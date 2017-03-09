
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 88 33 00 00       	call   f01033e5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 38 10 f0       	push   $0xf0103880
f010006f:	e8 88 28 00 00       	call   f01028fc <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 32 11 00 00       	call   f01011ab <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 8b 07 00 00       	call   f0100811 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 9b 38 10 f0       	push   $0xf010389b
f01000b5:	e8 42 28 00 00       	call   f01028fc <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 12 28 00 00       	call   f01028d6 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 fe 40 10 f0 	movl   $0xf01040fe,(%esp)
f01000cb:	e8 2c 28 00 00       	call   f01028fc <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 34 07 00 00       	call   f0100811 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 b3 38 10 f0       	push   $0xf01038b3
f01000f7:	e8 00 28 00 00       	call   f01028fc <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ce 27 00 00       	call   f01028d6 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 fe 40 10 f0 	movl   $0xf01040fe,(%esp)
f010010f:	e8 e8 27 00 00       	call   f01028fc <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 20 3a 10 f0 	movzbl -0xfefc5e0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 20 3a 10 f0 	movzbl -0xfefc5e0(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 20 39 10 f0 	movzbl -0xfefc6e0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 00 39 10 f0 	mov    -0xfefc700(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 cd 38 10 f0       	push   $0xf01038cd
f010026d:	e8 8a 26 00 00       	call   f01028fc <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 11 30 00 00       	call   f0103432 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 d9 38 10 f0       	push   $0xf01038d9
f01005f0:	e8 07 23 00 00       	call   f01028fc <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 20 3b 10 f0       	push   $0xf0103b20
f0100636:	68 3e 3b 10 f0       	push   $0xf0103b3e
f010063b:	68 43 3b 10 f0       	push   $0xf0103b43
f0100640:	e8 b7 22 00 00       	call   f01028fc <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 f0 3b 10 f0       	push   $0xf0103bf0
f010064d:	68 4c 3b 10 f0       	push   $0xf0103b4c
f0100652:	68 43 3b 10 f0       	push   $0xf0103b43
f0100657:	e8 a0 22 00 00       	call   f01028fc <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 55 3b 10 f0       	push   $0xf0103b55
f010066e:	e8 89 22 00 00       	call   f01028fc <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 18 3c 10 f0       	push   $0xf0103c18
f0100680:	e8 77 22 00 00       	call   f01028fc <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 40 3c 10 f0       	push   $0xf0103c40
f0100697:	e8 60 22 00 00       	call   f01028fc <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 71 38 10 00       	push   $0x103871
f01006a4:	68 71 38 10 f0       	push   $0xf0103871
f01006a9:	68 64 3c 10 f0       	push   $0xf0103c64
f01006ae:	e8 49 22 00 00       	call   f01028fc <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 73 11 00       	push   $0x117300
f01006bb:	68 00 73 11 f0       	push   $0xf0117300
f01006c0:	68 88 3c 10 f0       	push   $0xf0103c88
f01006c5:	e8 32 22 00 00       	call   f01028fc <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 70 79 11 00       	push   $0x117970
f01006d2:	68 70 79 11 f0       	push   $0xf0117970
f01006d7:	68 ac 3c 10 f0       	push   $0xf0103cac
f01006dc:	e8 1b 22 00 00       	call   f01028fc <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 d0 3c 10 f0       	push   $0xf0103cd0
f0100707:	e8 f0 21 00 00       	call   f01028fc <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	57                   	push   %edi
f0100717:	56                   	push   %esi
f0100718:	53                   	push   %ebx
f0100719:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010071c:	89 e8                	mov    %ebp,%eax
 	uint32_t* ebp = (uint32_t*) read_ebp();
f010071e:	89 c6                	mov    %eax,%esi
	uint32_t eip = ebp[1];
f0100720:	8b 40 04             	mov    0x4(%eax),%eax
f0100723:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  	cprintf("Stack backtrace:\n");
f0100726:	68 6e 3b 10 f0       	push   $0xf0103b6e
f010072b:	e8 cc 21 00 00       	call   f01028fc <cprintf>
	while(ebp){
f0100730:	83 c4 10             	add    $0x10,%esp
f0100733:	e9 c4 00 00 00       	jmp    f01007fc <mon_backtrace+0xe9>
	cprintf("ebp %x  eip %x  args", ebp, *(ebp+1));
f0100738:	83 ec 04             	sub    $0x4,%esp
f010073b:	ff 76 04             	pushl  0x4(%esi)
f010073e:	56                   	push   %esi
f010073f:	68 80 3b 10 f0       	push   $0xf0103b80
f0100744:	e8 b3 21 00 00       	call   f01028fc <cprintf>
	cprintf(" %x", *(ebp+2));
f0100749:	83 c4 08             	add    $0x8,%esp
f010074c:	ff 76 08             	pushl  0x8(%esi)
f010074f:	68 95 3b 10 f0       	push   $0xf0103b95
f0100754:	e8 a3 21 00 00       	call   f01028fc <cprintf>
    	cprintf(" %x", *(ebp+3));
f0100759:	83 c4 08             	add    $0x8,%esp
f010075c:	ff 76 0c             	pushl  0xc(%esi)
f010075f:	68 95 3b 10 f0       	push   $0xf0103b95
f0100764:	e8 93 21 00 00       	call   f01028fc <cprintf>
    	cprintf(" %x", *(ebp+4));
f0100769:	83 c4 08             	add    $0x8,%esp
f010076c:	ff 76 10             	pushl  0x10(%esi)
f010076f:	68 95 3b 10 f0       	push   $0xf0103b95
f0100774:	e8 83 21 00 00       	call   f01028fc <cprintf>
    	cprintf(" %x", *(ebp+5));
f0100779:	83 c4 08             	add    $0x8,%esp
f010077c:	ff 76 14             	pushl  0x14(%esi)
f010077f:	68 95 3b 10 f0       	push   $0xf0103b95
f0100784:	e8 73 21 00 00       	call   f01028fc <cprintf>
    	cprintf(" %x\n", *(ebp+6));
f0100789:	83 c4 08             	add    $0x8,%esp
f010078c:	ff 76 18             	pushl  0x18(%esi)
f010078f:	68 fb 3f 10 f0       	push   $0xf0103ffb
f0100794:	e8 63 21 00 00       	call   f01028fc <cprintf>
	ebp = (uint32_t*) *ebp;
f0100799:	8b 36                	mov    (%esi),%esi
f010079b:	8d 5e 08             	lea    0x8(%esi),%ebx
f010079e:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007a1:	83 c4 10             	add    $0x10,%esp
        int i;
    	for (i = 2; i <= 6; ++i)
      cprintf(" %08.x", ebp[i]);
f01007a4:	83 ec 08             	sub    $0x8,%esp
f01007a7:	ff 33                	pushl  (%ebx)
f01007a9:	68 99 3b 10 f0       	push   $0xf0103b99
f01007ae:	e8 49 21 00 00       	call   f01028fc <cprintf>
f01007b3:	83 c3 04             	add    $0x4,%ebx
    	cprintf(" %x", *(ebp+4));
    	cprintf(" %x", *(ebp+5));
    	cprintf(" %x\n", *(ebp+6));
	ebp = (uint32_t*) *ebp;
        int i;
    	for (i = 2; i <= 6; ++i)
f01007b6:	83 c4 10             	add    $0x10,%esp
f01007b9:	39 fb                	cmp    %edi,%ebx
f01007bb:	75 e7                	jne    f01007a4 <mon_backtrace+0x91>
      cprintf(" %08.x", ebp[i]);
      cprintf("\n");
f01007bd:	83 ec 0c             	sub    $0xc,%esp
f01007c0:	68 fe 40 10 f0       	push   $0xf01040fe
f01007c5:	e8 32 21 00 00       	call   f01028fc <cprintf>
     struct Eipdebuginfo info;
     debuginfo_eip(eip, &info);
f01007ca:	83 c4 08             	add    $0x8,%esp
f01007cd:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007d0:	50                   	push   %eax
f01007d1:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01007d4:	57                   	push   %edi
f01007d5:	e8 2c 22 00 00       	call   f0102a06 <debuginfo_eip>
     cprintf("\t%s:%d: %.*s+%d\n", 
f01007da:	83 c4 08             	add    $0x8,%esp
f01007dd:	89 f8                	mov    %edi,%eax
f01007df:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007e2:	50                   	push   %eax
f01007e3:	ff 75 d8             	pushl  -0x28(%ebp)
f01007e6:	ff 75 dc             	pushl  -0x24(%ebp)
f01007e9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007ec:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ef:	68 a0 3b 10 f0       	push   $0xf0103ba0
f01007f4:	e8 03 21 00 00       	call   f01028fc <cprintf>
f01007f9:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
 	uint32_t* ebp = (uint32_t*) read_ebp();
	uint32_t eip = ebp[1];
  	cprintf("Stack backtrace:\n");
	while(ebp){
f01007fc:	85 f6                	test   %esi,%esi
f01007fe:	0f 85 34 ff ff ff    	jne    f0100738 <mon_backtrace+0x25>
      info.eip_fn_namelen, info.eip_fn_name,
      eip-info.eip_fn_addr);
        }

	return 0;
}
f0100804:	b8 00 00 00 00       	mov    $0x0,%eax
f0100809:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010080c:	5b                   	pop    %ebx
f010080d:	5e                   	pop    %esi
f010080e:	5f                   	pop    %edi
f010080f:	5d                   	pop    %ebp
f0100810:	c3                   	ret    

f0100811 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100811:	55                   	push   %ebp
f0100812:	89 e5                	mov    %esp,%ebp
f0100814:	57                   	push   %edi
f0100815:	56                   	push   %esi
f0100816:	53                   	push   %ebx
f0100817:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010081a:	68 fc 3c 10 f0       	push   $0xf0103cfc
f010081f:	e8 d8 20 00 00       	call   f01028fc <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100824:	c7 04 24 20 3d 10 f0 	movl   $0xf0103d20,(%esp)
f010082b:	e8 cc 20 00 00       	call   f01028fc <cprintf>
f0100830:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100833:	83 ec 0c             	sub    $0xc,%esp
f0100836:	68 b1 3b 10 f0       	push   $0xf0103bb1
f010083b:	e8 4e 29 00 00       	call   f010318e <readline>
f0100840:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100842:	83 c4 10             	add    $0x10,%esp
f0100845:	85 c0                	test   %eax,%eax
f0100847:	74 ea                	je     f0100833 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100849:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100850:	be 00 00 00 00       	mov    $0x0,%esi
f0100855:	eb 0a                	jmp    f0100861 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100857:	c6 03 00             	movb   $0x0,(%ebx)
f010085a:	89 f7                	mov    %esi,%edi
f010085c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010085f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100861:	0f b6 03             	movzbl (%ebx),%eax
f0100864:	84 c0                	test   %al,%al
f0100866:	74 63                	je     f01008cb <monitor+0xba>
f0100868:	83 ec 08             	sub    $0x8,%esp
f010086b:	0f be c0             	movsbl %al,%eax
f010086e:	50                   	push   %eax
f010086f:	68 b5 3b 10 f0       	push   $0xf0103bb5
f0100874:	e8 2f 2b 00 00       	call   f01033a8 <strchr>
f0100879:	83 c4 10             	add    $0x10,%esp
f010087c:	85 c0                	test   %eax,%eax
f010087e:	75 d7                	jne    f0100857 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100880:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100883:	74 46                	je     f01008cb <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100885:	83 fe 0f             	cmp    $0xf,%esi
f0100888:	75 14                	jne    f010089e <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	6a 10                	push   $0x10
f010088f:	68 ba 3b 10 f0       	push   $0xf0103bba
f0100894:	e8 63 20 00 00       	call   f01028fc <cprintf>
f0100899:	83 c4 10             	add    $0x10,%esp
f010089c:	eb 95                	jmp    f0100833 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010089e:	8d 7e 01             	lea    0x1(%esi),%edi
f01008a1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a5:	eb 03                	jmp    f01008aa <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008a7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008aa:	0f b6 03             	movzbl (%ebx),%eax
f01008ad:	84 c0                	test   %al,%al
f01008af:	74 ae                	je     f010085f <monitor+0x4e>
f01008b1:	83 ec 08             	sub    $0x8,%esp
f01008b4:	0f be c0             	movsbl %al,%eax
f01008b7:	50                   	push   %eax
f01008b8:	68 b5 3b 10 f0       	push   $0xf0103bb5
f01008bd:	e8 e6 2a 00 00       	call   f01033a8 <strchr>
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 de                	je     f01008a7 <monitor+0x96>
f01008c9:	eb 94                	jmp    f010085f <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008cb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008d2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008d3:	85 f6                	test   %esi,%esi
f01008d5:	0f 84 58 ff ff ff    	je     f0100833 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008db:	83 ec 08             	sub    $0x8,%esp
f01008de:	68 3e 3b 10 f0       	push   $0xf0103b3e
f01008e3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e6:	e8 5f 2a 00 00       	call   f010334a <strcmp>
f01008eb:	83 c4 10             	add    $0x10,%esp
f01008ee:	85 c0                	test   %eax,%eax
f01008f0:	74 1e                	je     f0100910 <monitor+0xff>
f01008f2:	83 ec 08             	sub    $0x8,%esp
f01008f5:	68 4c 3b 10 f0       	push   $0xf0103b4c
f01008fa:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fd:	e8 48 2a 00 00       	call   f010334a <strcmp>
f0100902:	83 c4 10             	add    $0x10,%esp
f0100905:	85 c0                	test   %eax,%eax
f0100907:	75 2f                	jne    f0100938 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100909:	b8 01 00 00 00       	mov    $0x1,%eax
f010090e:	eb 05                	jmp    f0100915 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100910:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100915:	83 ec 04             	sub    $0x4,%esp
f0100918:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010091b:	01 d0                	add    %edx,%eax
f010091d:	ff 75 08             	pushl  0x8(%ebp)
f0100920:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100923:	51                   	push   %ecx
f0100924:	56                   	push   %esi
f0100925:	ff 14 85 50 3d 10 f0 	call   *-0xfefc2b0(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010092c:	83 c4 10             	add    $0x10,%esp
f010092f:	85 c0                	test   %eax,%eax
f0100931:	78 1d                	js     f0100950 <monitor+0x13f>
f0100933:	e9 fb fe ff ff       	jmp    f0100833 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	ff 75 a8             	pushl  -0x58(%ebp)
f010093e:	68 d7 3b 10 f0       	push   $0xf0103bd7
f0100943:	e8 b4 1f 00 00       	call   f01028fc <cprintf>
f0100948:	83 c4 10             	add    $0x10,%esp
f010094b:	e9 e3 fe ff ff       	jmp    f0100833 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100950:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100953:	5b                   	pop    %ebx
f0100954:	5e                   	pop    %esi
f0100955:	5f                   	pop    %edi
f0100956:	5d                   	pop    %ebp
f0100957:	c3                   	ret    

f0100958 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100958:	55                   	push   %ebp
f0100959:	89 e5                	mov    %esp,%ebp
f010095b:	56                   	push   %esi
f010095c:	53                   	push   %ebx
f010095d:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010095f:	83 ec 0c             	sub    $0xc,%esp
f0100962:	50                   	push   %eax
f0100963:	e8 2d 1f 00 00       	call   f0102895 <mc146818_read>
f0100968:	89 c6                	mov    %eax,%esi
f010096a:	83 c3 01             	add    $0x1,%ebx
f010096d:	89 1c 24             	mov    %ebx,(%esp)
f0100970:	e8 20 1f 00 00       	call   f0102895 <mc146818_read>
f0100975:	c1 e0 08             	shl    $0x8,%eax
f0100978:	09 f0                	or     %esi,%eax
}
f010097a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010097d:	5b                   	pop    %ebx
f010097e:	5e                   	pop    %esi
f010097f:	5d                   	pop    %ebp
f0100980:	c3                   	ret    

f0100981 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100981:	55                   	push   %ebp
f0100982:	89 e5                	mov    %esp,%ebp
f0100984:	56                   	push   %esi
f0100985:	53                   	push   %ebx
f0100986:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100988:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f010098f:	75 0f                	jne    f01009a0 <boot_alloc+0x1f>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100991:	b8 6f 89 11 f0       	mov    $0xf011896f,%eax
f0100996:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099b:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
        cprintf("entering boot_alloc\n");
f01009a0:	83 ec 0c             	sub    $0xc,%esp
f01009a3:	68 60 3d 10 f0       	push   $0xf0103d60
f01009a8:	e8 4f 1f 00 00       	call   f01028fc <cprintf>
        cprintf("next memory at %x\n", ROUNDUP((char*) (nextfree+n), PGSIZE));
f01009ad:	89 d8                	mov    %ebx,%eax
f01009af:	03 05 38 75 11 f0    	add    0xf0117538,%eax
f01009b5:	05 ff 0f 00 00       	add    $0xfff,%eax
f01009ba:	83 c4 08             	add    $0x8,%esp
f01009bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c2:	50                   	push   %eax
f01009c3:	68 75 3d 10 f0       	push   $0xf0103d75
f01009c8:	e8 2f 1f 00 00       	call   f01028fc <cprintf>
        result = nextfree;
f01009cd:	8b 35 38 75 11 f0    	mov    0xf0117538,%esi
    if (n > 0){
f01009d3:	83 c4 10             	add    $0x10,%esp
f01009d6:	85 db                	test   %ebx,%ebx
f01009d8:	74 4a                	je     f0100a24 <boot_alloc+0xa3>
	cprintf("entering if function\n");
f01009da:	83 ec 0c             	sub    $0xc,%esp
f01009dd:	68 88 3d 10 f0       	push   $0xf0103d88
f01009e2:	e8 15 1f 00 00       	call   f01028fc <cprintf>
        free_address = (uint32_t)ROUNDUP((char *) ((uint32_t)nextfree + (uint32_t)n), PGSIZE);
f01009e7:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f01009ec:	8d 84 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%eax
f01009f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
        if(free_address > (uint32_t)KERNBASE && free_address <  (uint32_t)KERNBASE + 0x400000)
f01009f8:	8d 90 ff ff ff 0f    	lea    0xfffffff(%eax),%edx
f01009fe:	83 c4 10             	add    $0x10,%esp
f0100a01:	81 fa fe ff 3f 00    	cmp    $0x3ffffe,%edx
f0100a07:	77 07                	ja     f0100a10 <boot_alloc+0x8f>
            nextfree = (char *)free_address;
f0100a09:	a3 38 75 11 f0       	mov    %eax,0xf0117538
f0100a0e:	eb 14                	jmp    f0100a24 <boot_alloc+0xa3>
        else
            panic("Out of Memory!");
f0100a10:	83 ec 04             	sub    $0x4,%esp
f0100a13:	68 9e 3d 10 f0       	push   $0xf0103d9e
f0100a18:	6a 72                	push   $0x72
f0100a1a:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100a1f:	e8 67 f6 ff ff       	call   f010008b <_panic>
    }
    else if(n < 0){
        panic("Cannot allocate negative");
    }
    return (void *) result;
}
f0100a24:	89 f0                	mov    %esi,%eax
f0100a26:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a29:	5b                   	pop    %ebx
f0100a2a:	5e                   	pop    %esi
f0100a2b:	5d                   	pop    %ebp
f0100a2c:	c3                   	ret    

f0100a2d <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a2d:	89 d1                	mov    %edx,%ecx
f0100a2f:	c1 e9 16             	shr    $0x16,%ecx
f0100a32:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a35:	a8 01                	test   $0x1,%al
f0100a37:	74 52                	je     f0100a8b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a3e:	89 c1                	mov    %eax,%ecx
f0100a40:	c1 e9 0c             	shr    $0xc,%ecx
f0100a43:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a49:	72 1b                	jb     f0100a66 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a4b:	55                   	push   %ebp
f0100a4c:	89 e5                	mov    %esp,%ebp
f0100a4e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a51:	50                   	push   %eax
f0100a52:	68 30 41 10 f0       	push   $0xf0104130
f0100a57:	68 28 03 00 00       	push   $0x328
f0100a5c:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100a61:	e8 25 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a66:	c1 ea 0c             	shr    $0xc,%edx
f0100a69:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a6f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a76:	89 c2                	mov    %eax,%edx
f0100a78:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a7b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a80:	85 d2                	test   %edx,%edx
f0100a82:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a87:	0f 44 c2             	cmove  %edx,%eax
f0100a8a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a90:	c3                   	ret    

f0100a91 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a91:	55                   	push   %ebp
f0100a92:	89 e5                	mov    %esp,%ebp
f0100a94:	57                   	push   %edi
f0100a95:	56                   	push   %esi
f0100a96:	53                   	push   %ebx
f0100a97:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a9a:	84 c0                	test   %al,%al
f0100a9c:	0f 85 72 02 00 00    	jne    f0100d14 <check_page_free_list+0x283>
f0100aa2:	e9 7f 02 00 00       	jmp    f0100d26 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100aa7:	83 ec 04             	sub    $0x4,%esp
f0100aaa:	68 54 41 10 f0       	push   $0xf0104154
f0100aaf:	68 6b 02 00 00       	push   $0x26b
f0100ab4:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100ab9:	e8 cd f5 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100abe:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ac1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ac4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ac7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100aca:	89 c2                	mov    %eax,%edx
f0100acc:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100ad2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ad8:	0f 95 c2             	setne  %dl
f0100adb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ade:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ae2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ae4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ae8:	8b 00                	mov    (%eax),%eax
f0100aea:	85 c0                	test   %eax,%eax
f0100aec:	75 dc                	jne    f0100aca <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100aee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100af7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100afa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100afd:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b02:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b07:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0c:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b12:	eb 53                	jmp    f0100b67 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b14:	89 d8                	mov    %ebx,%eax
f0100b16:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b1c:	c1 f8 03             	sar    $0x3,%eax
f0100b1f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b22:	89 c2                	mov    %eax,%edx
f0100b24:	c1 ea 16             	shr    $0x16,%edx
f0100b27:	39 f2                	cmp    %esi,%edx
f0100b29:	73 3a                	jae    f0100b65 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b2b:	89 c2                	mov    %eax,%edx
f0100b2d:	c1 ea 0c             	shr    $0xc,%edx
f0100b30:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b36:	72 12                	jb     f0100b4a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b38:	50                   	push   %eax
f0100b39:	68 30 41 10 f0       	push   $0xf0104130
f0100b3e:	6a 52                	push   $0x52
f0100b40:	68 b9 3d 10 f0       	push   $0xf0103db9
f0100b45:	e8 41 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b4a:	83 ec 04             	sub    $0x4,%esp
f0100b4d:	68 80 00 00 00       	push   $0x80
f0100b52:	68 97 00 00 00       	push   $0x97
f0100b57:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b5c:	50                   	push   %eax
f0100b5d:	e8 83 28 00 00       	call   f01033e5 <memset>
f0100b62:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b65:	8b 1b                	mov    (%ebx),%ebx
f0100b67:	85 db                	test   %ebx,%ebx
f0100b69:	75 a9                	jne    f0100b14 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b70:	e8 0c fe ff ff       	call   f0100981 <boot_alloc>
f0100b75:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b78:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b7e:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b84:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b89:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b8c:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b8f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b92:	be 00 00 00 00       	mov    $0x0,%esi
f0100b97:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b9a:	e9 30 01 00 00       	jmp    f0100ccf <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b9f:	39 ca                	cmp    %ecx,%edx
f0100ba1:	73 19                	jae    f0100bbc <check_page_free_list+0x12b>
f0100ba3:	68 c7 3d 10 f0       	push   $0xf0103dc7
f0100ba8:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100bad:	68 85 02 00 00       	push   $0x285
f0100bb2:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100bb7:	e8 cf f4 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100bbc:	39 fa                	cmp    %edi,%edx
f0100bbe:	72 19                	jb     f0100bd9 <check_page_free_list+0x148>
f0100bc0:	68 e8 3d 10 f0       	push   $0xf0103de8
f0100bc5:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100bca:	68 86 02 00 00       	push   $0x286
f0100bcf:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100bd4:	e8 b2 f4 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd9:	89 d0                	mov    %edx,%eax
f0100bdb:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100bde:	a8 07                	test   $0x7,%al
f0100be0:	74 19                	je     f0100bfb <check_page_free_list+0x16a>
f0100be2:	68 78 41 10 f0       	push   $0xf0104178
f0100be7:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100bec:	68 87 02 00 00       	push   $0x287
f0100bf1:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100bf6:	e8 90 f4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bfb:	c1 f8 03             	sar    $0x3,%eax
f0100bfe:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c01:	85 c0                	test   %eax,%eax
f0100c03:	75 19                	jne    f0100c1e <check_page_free_list+0x18d>
f0100c05:	68 fc 3d 10 f0       	push   $0xf0103dfc
f0100c0a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100c0f:	68 8a 02 00 00       	push   $0x28a
f0100c14:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100c19:	e8 6d f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c1e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c23:	75 19                	jne    f0100c3e <check_page_free_list+0x1ad>
f0100c25:	68 0d 3e 10 f0       	push   $0xf0103e0d
f0100c2a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100c2f:	68 8b 02 00 00       	push   $0x28b
f0100c34:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100c39:	e8 4d f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c3e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c43:	75 19                	jne    f0100c5e <check_page_free_list+0x1cd>
f0100c45:	68 ac 41 10 f0       	push   $0xf01041ac
f0100c4a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100c4f:	68 8c 02 00 00       	push   $0x28c
f0100c54:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100c59:	e8 2d f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c5e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c63:	75 19                	jne    f0100c7e <check_page_free_list+0x1ed>
f0100c65:	68 26 3e 10 f0       	push   $0xf0103e26
f0100c6a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100c6f:	68 8d 02 00 00       	push   $0x28d
f0100c74:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100c79:	e8 0d f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c7e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c83:	76 3f                	jbe    f0100cc4 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c85:	89 c3                	mov    %eax,%ebx
f0100c87:	c1 eb 0c             	shr    $0xc,%ebx
f0100c8a:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c8d:	77 12                	ja     f0100ca1 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c8f:	50                   	push   %eax
f0100c90:	68 30 41 10 f0       	push   $0xf0104130
f0100c95:	6a 52                	push   $0x52
f0100c97:	68 b9 3d 10 f0       	push   $0xf0103db9
f0100c9c:	e8 ea f3 ff ff       	call   f010008b <_panic>
f0100ca1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ca6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100ca9:	76 1e                	jbe    f0100cc9 <check_page_free_list+0x238>
f0100cab:	68 d0 41 10 f0       	push   $0xf01041d0
f0100cb0:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100cb5:	68 8e 02 00 00       	push   $0x28e
f0100cba:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100cbf:	e8 c7 f3 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100cc4:	83 c6 01             	add    $0x1,%esi
f0100cc7:	eb 04                	jmp    f0100ccd <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100cc9:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ccd:	8b 12                	mov    (%edx),%edx
f0100ccf:	85 d2                	test   %edx,%edx
f0100cd1:	0f 85 c8 fe ff ff    	jne    f0100b9f <check_page_free_list+0x10e>
f0100cd7:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100cda:	85 f6                	test   %esi,%esi
f0100cdc:	7f 19                	jg     f0100cf7 <check_page_free_list+0x266>
f0100cde:	68 40 3e 10 f0       	push   $0xf0103e40
f0100ce3:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100ce8:	68 96 02 00 00       	push   $0x296
f0100ced:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100cf2:	e8 94 f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100cf7:	85 db                	test   %ebx,%ebx
f0100cf9:	7f 42                	jg     f0100d3d <check_page_free_list+0x2ac>
f0100cfb:	68 52 3e 10 f0       	push   $0xf0103e52
f0100d00:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100d05:	68 97 02 00 00       	push   $0x297
f0100d0a:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100d0f:	e8 77 f3 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d14:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100d19:	85 c0                	test   %eax,%eax
f0100d1b:	0f 85 9d fd ff ff    	jne    f0100abe <check_page_free_list+0x2d>
f0100d21:	e9 81 fd ff ff       	jmp    f0100aa7 <check_page_free_list+0x16>
f0100d26:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100d2d:	0f 84 74 fd ff ff    	je     f0100aa7 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d33:	be 00 04 00 00       	mov    $0x400,%esi
f0100d38:	e9 cf fd ff ff       	jmp    f0100b0c <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100d3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d40:	5b                   	pop    %ebx
f0100d41:	5e                   	pop    %esi
f0100d42:	5f                   	pop    %edi
f0100d43:	5d                   	pop    %ebp
f0100d44:	c3                   	ret    

f0100d45 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d45:	55                   	push   %ebp
f0100d46:	89 e5                	mov    %esp,%ebp
f0100d48:	56                   	push   %esi
f0100d49:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100d4a:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100d50:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d56:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d5b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100d60:	eb 27                	jmp    f0100d89 <page_init+0x44>
		pages[i].pp_ref = 0;
f0100d62:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d69:	89 d1                	mov    %edx,%ecx
f0100d6b:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d71:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d77:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100d79:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100d7c:	89 d3                	mov    %edx,%ebx
f0100d7e:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
f0100d84:	ba 01 00 00 00       	mov    $0x1,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100d89:	39 f0                	cmp    %esi,%eax
f0100d8b:	72 d5                	jb     f0100d62 <page_init+0x1d>
f0100d8d:	84 d2                	test   %dl,%dl
f0100d8f:	74 06                	je     f0100d97 <page_init+0x52>
f0100d91:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	cprintf("npages_basemem=%d\n", npages_basemem);
f0100d97:	83 ec 08             	sub    $0x8,%esp
f0100d9a:	56                   	push   %esi
f0100d9b:	68 63 3e 10 f0       	push   $0xf0103e63
f0100da0:	e8 57 1b 00 00       	call   f01028fc <cprintf>
 	int med = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
f0100da5:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0100dab:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100db0:	8d 14 c5 00 00 00 10 	lea    0x10000000(,%eax,8),%edx
f0100db7:	8d 84 11 ff 0f 00 00 	lea    0xfff(%ecx,%edx,1),%eax
f0100dbe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dc3:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0100dc9:	83 c4 08             	add    $0x8,%esp
f0100dcc:	85 c0                	test   %eax,%eax
f0100dce:	0f 48 c3             	cmovs  %ebx,%eax
f0100dd1:	c1 f8 0c             	sar    $0xc,%eax
f0100dd4:	89 c3                	mov    %eax,%ebx
	    cprintf("%d\n", ((char*)pages) + (sizeof(struct PageInfo) * npages));
f0100dd6:	8d 84 11 00 00 00 f0 	lea    -0x10000000(%ecx,%edx,1),%eax
f0100ddd:	50                   	push   %eax
f0100dde:	68 ad 3b 10 f0       	push   $0xf0103bad
f0100de3:	e8 14 1b 00 00       	call   f01028fc <cprintf>
	    cprintf("med=%d\n", med);
f0100de8:	83 c4 08             	add    $0x8,%esp
f0100deb:	53                   	push   %ebx
f0100dec:	68 76 3e 10 f0       	push   $0xf0103e76
f0100df1:	e8 06 1b 00 00       	call   f01028fc <cprintf>
        for (i = med; i < npages; i++) {
f0100df6:	89 da                	mov    %ebx,%edx
f0100df8:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
f0100dfe:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100e05:	83 c4 10             	add    $0x10,%esp
f0100e08:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e0d:	eb 23                	jmp    f0100e32 <page_init+0xed>
        	pages[i].pp_ref = 0;
f0100e0f:	89 c1                	mov    %eax,%ecx
f0100e11:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100e17:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
        	pages[i].pp_link = page_free_list;
f0100e1d:	89 31                	mov    %esi,(%ecx)
        	page_free_list = &pages[i];
f0100e1f:	89 c6                	mov    %eax,%esi
f0100e21:	03 35 6c 79 11 f0    	add    0xf011796c,%esi
	}
	cprintf("npages_basemem=%d\n", npages_basemem);
 	int med = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
	    cprintf("%d\n", ((char*)pages) + (sizeof(struct PageInfo) * npages));
	    cprintf("med=%d\n", med);
        for (i = med; i < npages; i++) {
f0100e27:	83 c2 01             	add    $0x1,%edx
f0100e2a:	83 c0 08             	add    $0x8,%eax
f0100e2d:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100e32:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e38:	72 d5                	jb     f0100e0f <page_init+0xca>
f0100e3a:	84 c9                	test   %cl,%cl
f0100e3c:	74 06                	je     f0100e44 <page_init+0xff>
f0100e3e:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
        	pages[i].pp_ref = 0;
        	pages[i].pp_link = page_free_list;
        	page_free_list = &pages[i];
    }
}
f0100e44:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e47:	5b                   	pop    %ebx
f0100e48:	5e                   	pop    %esi
f0100e49:	5d                   	pop    %ebp
f0100e4a:	c3                   	ret    

f0100e4b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e4b:	55                   	push   %ebp
f0100e4c:	89 e5                	mov    %esp,%ebp
f0100e4e:	53                   	push   %ebx
f0100e4f:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
        if (page_free_list)
f0100e52:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e58:	85 db                	test   %ebx,%ebx
f0100e5a:	74 52                	je     f0100eae <page_alloc+0x63>
{
        struct PageInfo *ret = page_free_list;
        page_free_list = page_free_list->pp_link;
f0100e5c:	8b 03                	mov    (%ebx),%eax
f0100e5e:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
        if (alloc_flags & ALLOC_ZERO)
f0100e63:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e67:	74 45                	je     f0100eae <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e69:	89 d8                	mov    %ebx,%eax
f0100e6b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e71:	c1 f8 03             	sar    $0x3,%eax
f0100e74:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e77:	89 c2                	mov    %eax,%edx
f0100e79:	c1 ea 0c             	shr    $0xc,%edx
f0100e7c:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e82:	72 12                	jb     f0100e96 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e84:	50                   	push   %eax
f0100e85:	68 30 41 10 f0       	push   $0xf0104130
f0100e8a:	6a 52                	push   $0x52
f0100e8c:	68 b9 3d 10 f0       	push   $0xf0103db9
f0100e91:	e8 f5 f1 ff ff       	call   f010008b <_panic>
        memset(page2kva(ret), 0, PGSIZE);
f0100e96:	83 ec 04             	sub    $0x4,%esp
f0100e99:	68 00 10 00 00       	push   $0x1000
f0100e9e:	6a 00                	push   $0x0
f0100ea0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ea5:	50                   	push   %eax
f0100ea6:	e8 3a 25 00 00       	call   f01033e5 <memset>
f0100eab:	83 c4 10             	add    $0x10,%esp
        return ret;
}
	return NULL;
}
f0100eae:	89 d8                	mov    %ebx,%eax
f0100eb0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eb3:	c9                   	leave  
f0100eb4:	c3                   	ret    

f0100eb5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	83 ec 08             	sub    $0x8,%esp
f0100ebb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
         assert(pp->pp_ref==0)	;
f0100ebe:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ec3:	74 19                	je     f0100ede <page_free+0x29>
f0100ec5:	68 7e 3e 10 f0       	push   $0xf0103e7e
f0100eca:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0100ecf:	68 4c 01 00 00       	push   $0x14c
f0100ed4:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100ed9:	e8 ad f1 ff ff       	call   f010008b <_panic>
	//assert(pp->pp_link!=NULL);
         pp->pp_link = page_free_list;
f0100ede:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ee4:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;
f0100ee6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

         
}
f0100eeb:	c9                   	leave  
f0100eec:	c3                   	ret    

f0100eed <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100eed:	55                   	push   %ebp
f0100eee:	89 e5                	mov    %esp,%ebp
f0100ef0:	83 ec 08             	sub    $0x8,%esp
f0100ef3:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100ef6:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100efa:	83 e8 01             	sub    $0x1,%eax
f0100efd:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f01:	66 85 c0             	test   %ax,%ax
f0100f04:	75 0c                	jne    f0100f12 <page_decref+0x25>
		page_free(pp);
f0100f06:	83 ec 0c             	sub    $0xc,%esp
f0100f09:	52                   	push   %edx
f0100f0a:	e8 a6 ff ff ff       	call   f0100eb5 <page_free>
f0100f0f:	83 c4 10             	add    $0x10,%esp
}
f0100f12:	c9                   	leave  
f0100f13:	c3                   	ret    

f0100f14 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f14:	55                   	push   %ebp
f0100f15:	89 e5                	mov    %esp,%ebp
f0100f17:	56                   	push   %esi
f0100f18:	53                   	push   %ebx
f0100f19:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
 int dindex = PDX(va), tindex = PTX(va);
f0100f1c:	89 de                	mov    %ebx,%esi
f0100f1e:	c1 ee 0c             	shr    $0xc,%esi
f0100f21:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    //dir index, table index
    if (!(pgdir[dindex] & PTE_P)) { //if pde not exist
f0100f27:	c1 eb 16             	shr    $0x16,%ebx
f0100f2a:	c1 e3 02             	shl    $0x2,%ebx
f0100f2d:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f30:	f6 03 01             	testb  $0x1,(%ebx)
f0100f33:	75 2d                	jne    f0100f62 <pgdir_walk+0x4e>
        if (create) {
f0100f35:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f39:	74 59                	je     f0100f94 <pgdir_walk+0x80>
            struct PageInfo *pp = page_alloc(ALLOC_ZERO);   //alloc a zero page
f0100f3b:	83 ec 0c             	sub    $0xc,%esp
f0100f3e:	6a 01                	push   $0x1
f0100f40:	e8 06 ff ff ff       	call   f0100e4b <page_alloc>
            if (!pp) return NULL;   //allocation fails
f0100f45:	83 c4 10             	add    $0x10,%esp
f0100f48:	85 c0                	test   %eax,%eax
f0100f4a:	74 4f                	je     f0100f9b <pgdir_walk+0x87>
            pp->pp_ref++;
f0100f4c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
            pgdir[dindex] = page2pa(pp) | PTE_P | PTE_U | PTE_W;    
f0100f51:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f57:	c1 f8 03             	sar    $0x3,%eax
f0100f5a:	c1 e0 0c             	shl    $0xc,%eax
f0100f5d:	83 c8 07             	or     $0x7,%eax
f0100f60:	89 03                	mov    %eax,(%ebx)
            //we should use PTE_U and PTE_W to pass checkings
        } else return NULL;
    }
    pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
f0100f62:	8b 03                	mov    (%ebx),%eax
f0100f64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f69:	89 c2                	mov    %eax,%edx
f0100f6b:	c1 ea 0c             	shr    $0xc,%edx
f0100f6e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f74:	72 15                	jb     f0100f8b <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f76:	50                   	push   %eax
f0100f77:	68 30 41 10 f0       	push   $0xf0104130
f0100f7c:	68 84 01 00 00       	push   $0x184
f0100f81:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100f86:	e8 00 f1 ff ff       	call   f010008b <_panic>
    //      struct PageInfo *pg = page_alloc(ALLOC_ZERO);   //alloc a zero page
    //      pg->pp_ref++;
    //      p[tindex] = page2pa(pg) | PTE_P;
    //  } else return NULL;

    return p+tindex;
f0100f8b:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100f92:	eb 0c                	jmp    f0100fa0 <pgdir_walk+0x8c>
            struct PageInfo *pp = page_alloc(ALLOC_ZERO);   //alloc a zero page
            if (!pp) return NULL;   //allocation fails
            pp->pp_ref++;
            pgdir[dindex] = page2pa(pp) | PTE_P | PTE_U | PTE_W;    
            //we should use PTE_U and PTE_W to pass checkings
        } else return NULL;
f0100f94:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f99:	eb 05                	jmp    f0100fa0 <pgdir_walk+0x8c>
 int dindex = PDX(va), tindex = PTX(va);
    //dir index, table index
    if (!(pgdir[dindex] & PTE_P)) { //if pde not exist
        if (create) {
            struct PageInfo *pp = page_alloc(ALLOC_ZERO);   //alloc a zero page
            if (!pp) return NULL;   //allocation fails
f0100f9b:	b8 00 00 00 00       	mov    $0x0,%eax
             return (page2kva(pp) + PTX(va));  
             }    
}
return NULL;
cprintf ("exit pgdir\n");*/
}
f0100fa0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fa3:	5b                   	pop    %ebx
f0100fa4:	5e                   	pop    %esi
f0100fa5:	5d                   	pop    %ebp
f0100fa6:	c3                   	ret    

f0100fa7 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100fa7:	55                   	push   %ebp
f0100fa8:	89 e5                	mov    %esp,%ebp
f0100faa:	57                   	push   %edi
f0100fab:	56                   	push   %esi
f0100fac:	53                   	push   %ebx
f0100fad:	83 ec 1c             	sub    $0x1c,%esp
f0100fb0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fb3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fb6:	c1 e9 0c             	shr    $0xc,%ecx
f0100fb9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
       int i;
       //struct PageInfo *pp;
       for (i=0; i<size/PGSIZE; ++i)
f0100fbc:	89 c3                	mov    %eax,%ebx
f0100fbe:	be 00 00 00 00       	mov    $0x0,%esi
{
       
       pte_t *pte = pgdir_walk (pgdir, (void*)va, 1);
f0100fc3:	89 d7                	mov    %edx,%edi
f0100fc5:	29 c7                	sub    %eax,%edi
       if (!pte)
        panic ("boot_map_region panic, out of memory");
       *pte = pa | perm | PTE_P;
f0100fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fca:	83 c8 01             	or     $0x1,%eax
f0100fcd:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
       int i;
       //struct PageInfo *pp;
       for (i=0; i<size/PGSIZE; ++i)
f0100fd0:	eb 3f                	jmp    f0101011 <boot_map_region+0x6a>
{
       
       pte_t *pte = pgdir_walk (pgdir, (void*)va, 1);
f0100fd2:	83 ec 04             	sub    $0x4,%esp
f0100fd5:	6a 01                	push   $0x1
f0100fd7:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100fda:	50                   	push   %eax
f0100fdb:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fde:	e8 31 ff ff ff       	call   f0100f14 <pgdir_walk>
       if (!pte)
f0100fe3:	83 c4 10             	add    $0x10,%esp
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	75 17                	jne    f0101001 <boot_map_region+0x5a>
        panic ("boot_map_region panic, out of memory");
f0100fea:	83 ec 04             	sub    $0x4,%esp
f0100fed:	68 18 42 10 f0       	push   $0xf0104218
f0100ff2:	68 c1 01 00 00       	push   $0x1c1
f0100ff7:	68 ad 3d 10 f0       	push   $0xf0103dad
f0100ffc:	e8 8a f0 ff ff       	call   f010008b <_panic>
       *pte = pa | perm | PTE_P;
f0101001:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101004:	09 da                	or     %ebx,%edx
f0101006:	89 10                	mov    %edx,(%eax)
        va = va+ PGSIZE;
       pa = pa + PGSIZE;
f0101008:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
       int i;
       //struct PageInfo *pp;
       for (i=0; i<size/PGSIZE; ++i)
f010100e:	83 c6 01             	add    $0x1,%esi
f0101011:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101014:	75 bc                	jne    f0100fd2 <boot_map_region+0x2b>
        va = va+ PGSIZE;
       pa = pa + PGSIZE;

}      
        
}
f0101016:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101019:	5b                   	pop    %ebx
f010101a:	5e                   	pop    %esi
f010101b:	5f                   	pop    %edi
f010101c:	5d                   	pop    %ebp
f010101d:	c3                   	ret    

f010101e <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010101e:	55                   	push   %ebp
f010101f:	89 e5                	mov    %esp,%ebp
f0101021:	56                   	push   %esi
f0101022:	53                   	push   %ebx
f0101023:	8b 75 10             	mov    0x10(%ebp),%esi
      pte_t *pte;
      cprintf (" check ooo\n");
f0101026:	83 ec 0c             	sub    $0xc,%esp
f0101029:	68 8c 3e 10 f0       	push   $0xf0103e8c
f010102e:	e8 c9 18 00 00       	call   f01028fc <cprintf>
      pte=pgdir_walk (pgdir, va, 0);
f0101033:	83 c4 0c             	add    $0xc,%esp
f0101036:	6a 00                	push   $0x0
f0101038:	ff 75 0c             	pushl  0xc(%ebp)
f010103b:	ff 75 08             	pushl  0x8(%ebp)
f010103e:	e8 d1 fe ff ff       	call   f0100f14 <pgdir_walk>
f0101043:	89 c3                	mov    %eax,%ebx
      cprintf (" check ppp\n");
f0101045:	c7 04 24 98 3e 10 f0 	movl   $0xf0103e98,(%esp)
f010104c:	e8 ab 18 00 00       	call   f01028fc <cprintf>
      if (pte == NULL)
f0101051:	83 c4 10             	add    $0x10,%esp
f0101054:	85 db                	test   %ebx,%ebx
f0101056:	74 32                	je     f010108a <page_lookup+0x6c>
      {
       return NULL;
      }
      if (pte_store)
f0101058:	85 f6                	test   %esi,%esi
f010105a:	74 02                	je     f010105e <page_lookup+0x40>
       {
     *pte_store = pte;
f010105c:	89 1e                	mov    %ebx,(%esi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010105e:	8b 03                	mov    (%ebx),%eax
f0101060:	c1 e8 0c             	shr    $0xc,%eax
f0101063:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101069:	72 14                	jb     f010107f <page_lookup+0x61>
		panic("pa2page called with invalid pa");
f010106b:	83 ec 04             	sub    $0x4,%esp
f010106e:	68 40 42 10 f0       	push   $0xf0104240
f0101073:	6a 4b                	push   $0x4b
f0101075:	68 b9 3d 10 f0       	push   $0xf0103db9
f010107a:	e8 0c f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f010107f:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101085:	8d 04 c2             	lea    (%edx,%eax,8),%eax
       }
     
     return pa2page(PTE_ADDR(*pte)); 
f0101088:	eb 05                	jmp    f010108f <page_lookup+0x71>
      cprintf (" check ooo\n");
      pte=pgdir_walk (pgdir, va, 0);
      cprintf (" check ppp\n");
      if (pte == NULL)
      {
       return NULL;
f010108a:	b8 00 00 00 00       	mov    $0x0,%eax
       }
     
     return pa2page(PTE_ADDR(*pte)); 
    
	
}
f010108f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101092:	5b                   	pop    %ebx
f0101093:	5e                   	pop    %esi
f0101094:	5d                   	pop    %ebp
f0101095:	c3                   	ret    

f0101096 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101096:	55                   	push   %ebp
f0101097:	89 e5                	mov    %esp,%ebp
f0101099:	53                   	push   %ebx
f010109a:	83 ec 18             	sub    $0x18,%esp
f010109d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
    struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f01010a0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010a3:	50                   	push   %eax
f01010a4:	53                   	push   %ebx
f01010a5:	ff 75 08             	pushl  0x8(%ebp)
f01010a8:	e8 71 ff ff ff       	call   f010101e <page_lookup>
    if (!pp || !(*pte & PTE_P)) return; //page not exist
f01010ad:	83 c4 10             	add    $0x10,%esp
f01010b0:	85 c0                	test   %eax,%eax
f01010b2:	74 20                	je     f01010d4 <page_remove+0x3e>
f01010b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010b7:	f6 02 01             	testb  $0x1,(%edx)
f01010ba:	74 18                	je     f01010d4 <page_remove+0x3e>
//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
    page_decref(pp);
f01010bc:	83 ec 0c             	sub    $0xc,%esp
f01010bf:	50                   	push   %eax
f01010c0:	e8 28 fe ff ff       	call   f0100eed <page_decref>
//   - The pg table entry corresponding to 'va' should be set to 0.
    *pte = 0;
f01010c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010c8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010ce:	0f 01 3b             	invlpg (%ebx)
f01010d1:	83 c4 10             	add    $0x10,%esp
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
    tlb_invalidate(pgdir, va);
}
f01010d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010d7:	c9                   	leave  
f01010d8:	c3                   	ret    

f01010d9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010d9:	55                   	push   %ebp
f01010da:	89 e5                	mov    %esp,%ebp
f01010dc:	57                   	push   %edi
f01010dd:	56                   	push   %esi
f01010de:	53                   	push   %ebx
f01010df:	83 ec 10             	sub    $0x10,%esp
f01010e2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010e5:	8b 7d 10             	mov    0x10(%ebp),%edi
	//  Fill this function in
        
        pte_t *pte = pgdir_walk (pgdir, va, 0);
f01010e8:	6a 00                	push   $0x0
f01010ea:	57                   	push   %edi
f01010eb:	ff 75 08             	pushl  0x8(%ebp)
f01010ee:	e8 21 fe ff ff       	call   f0100f14 <pgdir_walk>
        
        if (pte != NULL)
f01010f3:	83 c4 10             	add    $0x10,%esp
f01010f6:	85 c0                	test   %eax,%eax
f01010f8:	74 28                	je     f0101122 <page_insert+0x49>
f01010fa:	89 c3                	mov    %eax,%ebx
       { 
          if (*pte & PTE_P)
f01010fc:	f6 00 01             	testb  $0x1,(%eax)
f01010ff:	74 0f                	je     f0101110 <page_insert+0x37>
          
         {
        page_remove(pgdir, va);
f0101101:	83 ec 08             	sub    $0x8,%esp
f0101104:	57                   	push   %edi
f0101105:	ff 75 08             	pushl  0x8(%ebp)
f0101108:	e8 89 ff ff ff       	call   f0101096 <page_remove>
f010110d:	83 c4 10             	add    $0x10,%esp
         
         } 
        if (page_free_list == pp)
f0101110:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101115:	39 f0                	cmp    %esi,%eax
f0101117:	75 39                	jne    f0101152 <page_insert+0x79>
        {
         page_free_list = page_free_list -> pp_link;
f0101119:	8b 00                	mov    (%eax),%eax
f010111b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0101120:	eb 30                	jmp    f0101152 <page_insert+0x79>
         
        } 
        }
    else 
{
        cprintf("dddddd\n");
f0101122:	83 ec 0c             	sub    $0xc,%esp
f0101125:	68 a4 3e 10 f0       	push   $0xf0103ea4
f010112a:	e8 cd 17 00 00       	call   f01028fc <cprintf>
         pte =pgdir_walk (pgdir, va, 1);
f010112f:	83 c4 0c             	add    $0xc,%esp
f0101132:	6a 01                	push   $0x1
f0101134:	57                   	push   %edi
f0101135:	ff 75 08             	pushl  0x8(%ebp)
f0101138:	e8 d7 fd ff ff       	call   f0100f14 <pgdir_walk>
f010113d:	89 c3                	mov    %eax,%ebx
         cprintf("create is true\n");
f010113f:	c7 04 24 ac 3e 10 f0 	movl   $0xf0103eac,(%esp)
f0101146:	e8 b1 17 00 00       	call   f01028fc <cprintf>
 
          if (!pte)
f010114b:	83 c4 10             	add    $0x10,%esp
f010114e:	85 db                	test   %ebx,%ebx
f0101150:	74 4c                	je     f010119e <page_insert+0xc5>
          {
          return -E_NO_MEM;
          cprintf("no memory\n");
          }
}
         cprintf("entering if function\n");
f0101152:	83 ec 0c             	sub    $0xc,%esp
f0101155:	68 88 3d 10 f0       	push   $0xf0103d88
f010115a:	e8 9d 17 00 00       	call   f01028fc <cprintf>
        *pte= page2pa(pp) | perm | PTE_P;
f010115f:	89 f0                	mov    %esi,%eax
f0101161:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101167:	c1 f8 03             	sar    $0x3,%eax
f010116a:	c1 e0 0c             	shl    $0xc,%eax
f010116d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101170:	83 ca 01             	or     $0x1,%edx
f0101173:	09 d0                	or     %edx,%eax
f0101175:	89 03                	mov    %eax,(%ebx)
         cprintf("entering if function\n");
f0101177:	c7 04 24 88 3d 10 f0 	movl   $0xf0103d88,(%esp)
f010117e:	e8 79 17 00 00       	call   f01028fc <cprintf>
         pp->pp_ref++; 
f0101183:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
         cprintf("exiting insert\n");
f0101188:	c7 04 24 bc 3e 10 f0 	movl   $0xf0103ebc,(%esp)
f010118f:	e8 68 17 00 00       	call   f01028fc <cprintf>
        
        return 0;
f0101194:	83 c4 10             	add    $0x10,%esp
f0101197:	b8 00 00 00 00       	mov    $0x0,%eax
f010119c:	eb 05                	jmp    f01011a3 <page_insert+0xca>
         pte =pgdir_walk (pgdir, va, 1);
         cprintf("create is true\n");
 
          if (!pte)
          {
          return -E_NO_MEM;
f010119e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
         cprintf("exiting insert\n");
        
        return 0;
        

}
f01011a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a6:	5b                   	pop    %ebx
f01011a7:	5e                   	pop    %esi
f01011a8:	5f                   	pop    %edi
f01011a9:	5d                   	pop    %ebp
f01011aa:	c3                   	ret    

f01011ab <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011ab:	55                   	push   %ebp
f01011ac:	89 e5                	mov    %esp,%ebp
f01011ae:	57                   	push   %edi
f01011af:	56                   	push   %esi
f01011b0:	53                   	push   %ebx
f01011b1:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01011b4:	b8 15 00 00 00       	mov    $0x15,%eax
f01011b9:	e8 9a f7 ff ff       	call   f0100958 <nvram_read>
f01011be:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01011c0:	b8 17 00 00 00       	mov    $0x17,%eax
f01011c5:	e8 8e f7 ff ff       	call   f0100958 <nvram_read>
f01011ca:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01011cc:	b8 34 00 00 00       	mov    $0x34,%eax
f01011d1:	e8 82 f7 ff ff       	call   f0100958 <nvram_read>
f01011d6:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01011d9:	85 c0                	test   %eax,%eax
f01011db:	74 07                	je     f01011e4 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01011dd:	05 00 40 00 00       	add    $0x4000,%eax
f01011e2:	eb 0b                	jmp    f01011ef <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01011e4:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01011ea:	85 f6                	test   %esi,%esi
f01011ec:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01011ef:	89 c2                	mov    %eax,%edx
f01011f1:	c1 ea 02             	shr    $0x2,%edx
f01011f4:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f01011fa:	89 da                	mov    %ebx,%edx
f01011fc:	c1 ea 02             	shr    $0x2,%edx
f01011ff:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101205:	89 c2                	mov    %eax,%edx
f0101207:	29 da                	sub    %ebx,%edx
f0101209:	52                   	push   %edx
f010120a:	53                   	push   %ebx
f010120b:	50                   	push   %eax
f010120c:	68 60 42 10 f0       	push   $0xf0104260
f0101211:	e8 e6 16 00 00       	call   f01028fc <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101216:	b8 00 10 00 00       	mov    $0x1000,%eax
f010121b:	e8 61 f7 ff ff       	call   f0100981 <boot_alloc>
f0101220:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101225:	83 c4 0c             	add    $0xc,%esp
f0101228:	68 00 10 00 00       	push   $0x1000
f010122d:	6a 00                	push   $0x0
f010122f:	50                   	push   %eax
f0101230:	e8 b0 21 00 00       	call   f01033e5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101235:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010123a:	83 c4 10             	add    $0x10,%esp
f010123d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101242:	77 15                	ja     f0101259 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101244:	50                   	push   %eax
f0101245:	68 9c 42 10 f0       	push   $0xf010429c
f010124a:	68 9f 00 00 00       	push   $0x9f
f010124f:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101254:	e8 32 ee ff ff       	call   f010008b <_panic>
f0101259:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010125f:	83 ca 05             	or     $0x5,%edx
f0101262:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:


	pages = (struct PageInfo* )boot_alloc(npages * sizeof(struct PageInfo));
f0101268:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010126d:	c1 e0 03             	shl    $0x3,%eax
f0101270:	e8 0c f7 ff ff       	call   f0100981 <boot_alloc>
f0101275:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010127a:	83 ec 04             	sub    $0x4,%esp
f010127d:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101283:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010128a:	52                   	push   %edx
f010128b:	6a 00                	push   $0x0
f010128d:	50                   	push   %eax
f010128e:	e8 52 21 00 00       	call   f01033e5 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101293:	e8 ad fa ff ff       	call   f0100d45 <page_init>

	check_page_free_list(1);
f0101298:	b8 01 00 00 00       	mov    $0x1,%eax
f010129d:	e8 ef f7 ff ff       	call   f0100a91 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012a2:	83 c4 10             	add    $0x10,%esp
f01012a5:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01012ac:	75 17                	jne    f01012c5 <mem_init+0x11a>
		panic("'pages' is a null pointer!");
f01012ae:	83 ec 04             	sub    $0x4,%esp
f01012b1:	68 cc 3e 10 f0       	push   $0xf0103ecc
f01012b6:	68 a8 02 00 00       	push   $0x2a8
f01012bb:	68 ad 3d 10 f0       	push   $0xf0103dad
f01012c0:	e8 c6 ed ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012c5:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012ca:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012cf:	eb 05                	jmp    f01012d6 <mem_init+0x12b>
		++nfree;
f01012d1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012d4:	8b 00                	mov    (%eax),%eax
f01012d6:	85 c0                	test   %eax,%eax
f01012d8:	75 f7                	jne    f01012d1 <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012da:	83 ec 0c             	sub    $0xc,%esp
f01012dd:	6a 00                	push   $0x0
f01012df:	e8 67 fb ff ff       	call   f0100e4b <page_alloc>
f01012e4:	89 c7                	mov    %eax,%edi
f01012e6:	83 c4 10             	add    $0x10,%esp
f01012e9:	85 c0                	test   %eax,%eax
f01012eb:	75 19                	jne    f0101306 <mem_init+0x15b>
f01012ed:	68 e7 3e 10 f0       	push   $0xf0103ee7
f01012f2:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01012f7:	68 b0 02 00 00       	push   $0x2b0
f01012fc:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101301:	e8 85 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101306:	83 ec 0c             	sub    $0xc,%esp
f0101309:	6a 00                	push   $0x0
f010130b:	e8 3b fb ff ff       	call   f0100e4b <page_alloc>
f0101310:	89 c6                	mov    %eax,%esi
f0101312:	83 c4 10             	add    $0x10,%esp
f0101315:	85 c0                	test   %eax,%eax
f0101317:	75 19                	jne    f0101332 <mem_init+0x187>
f0101319:	68 fd 3e 10 f0       	push   $0xf0103efd
f010131e:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101323:	68 b1 02 00 00       	push   $0x2b1
f0101328:	68 ad 3d 10 f0       	push   $0xf0103dad
f010132d:	e8 59 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101332:	83 ec 0c             	sub    $0xc,%esp
f0101335:	6a 00                	push   $0x0
f0101337:	e8 0f fb ff ff       	call   f0100e4b <page_alloc>
f010133c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010133f:	83 c4 10             	add    $0x10,%esp
f0101342:	85 c0                	test   %eax,%eax
f0101344:	75 19                	jne    f010135f <mem_init+0x1b4>
f0101346:	68 13 3f 10 f0       	push   $0xf0103f13
f010134b:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101350:	68 b2 02 00 00       	push   $0x2b2
f0101355:	68 ad 3d 10 f0       	push   $0xf0103dad
f010135a:	e8 2c ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010135f:	39 f7                	cmp    %esi,%edi
f0101361:	75 19                	jne    f010137c <mem_init+0x1d1>
f0101363:	68 29 3f 10 f0       	push   $0xf0103f29
f0101368:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010136d:	68 b5 02 00 00       	push   $0x2b5
f0101372:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101377:	e8 0f ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010137c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010137f:	39 c6                	cmp    %eax,%esi
f0101381:	74 04                	je     f0101387 <mem_init+0x1dc>
f0101383:	39 c7                	cmp    %eax,%edi
f0101385:	75 19                	jne    f01013a0 <mem_init+0x1f5>
f0101387:	68 c0 42 10 f0       	push   $0xf01042c0
f010138c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101391:	68 b6 02 00 00       	push   $0x2b6
f0101396:	68 ad 3d 10 f0       	push   $0xf0103dad
f010139b:	e8 eb ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013a0:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01013a6:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01013ac:	c1 e2 0c             	shl    $0xc,%edx
f01013af:	89 f8                	mov    %edi,%eax
f01013b1:	29 c8                	sub    %ecx,%eax
f01013b3:	c1 f8 03             	sar    $0x3,%eax
f01013b6:	c1 e0 0c             	shl    $0xc,%eax
f01013b9:	39 d0                	cmp    %edx,%eax
f01013bb:	72 19                	jb     f01013d6 <mem_init+0x22b>
f01013bd:	68 3b 3f 10 f0       	push   $0xf0103f3b
f01013c2:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01013c7:	68 b7 02 00 00       	push   $0x2b7
f01013cc:	68 ad 3d 10 f0       	push   $0xf0103dad
f01013d1:	e8 b5 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01013d6:	89 f0                	mov    %esi,%eax
f01013d8:	29 c8                	sub    %ecx,%eax
f01013da:	c1 f8 03             	sar    $0x3,%eax
f01013dd:	c1 e0 0c             	shl    $0xc,%eax
f01013e0:	39 c2                	cmp    %eax,%edx
f01013e2:	77 19                	ja     f01013fd <mem_init+0x252>
f01013e4:	68 58 3f 10 f0       	push   $0xf0103f58
f01013e9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01013ee:	68 b8 02 00 00       	push   $0x2b8
f01013f3:	68 ad 3d 10 f0       	push   $0xf0103dad
f01013f8:	e8 8e ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101400:	29 c8                	sub    %ecx,%eax
f0101402:	c1 f8 03             	sar    $0x3,%eax
f0101405:	c1 e0 0c             	shl    $0xc,%eax
f0101408:	39 c2                	cmp    %eax,%edx
f010140a:	77 19                	ja     f0101425 <mem_init+0x27a>
f010140c:	68 75 3f 10 f0       	push   $0xf0103f75
f0101411:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101416:	68 b9 02 00 00       	push   $0x2b9
f010141b:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101420:	e8 66 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101425:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010142a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010142d:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101434:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101437:	83 ec 0c             	sub    $0xc,%esp
f010143a:	6a 00                	push   $0x0
f010143c:	e8 0a fa ff ff       	call   f0100e4b <page_alloc>
f0101441:	83 c4 10             	add    $0x10,%esp
f0101444:	85 c0                	test   %eax,%eax
f0101446:	74 19                	je     f0101461 <mem_init+0x2b6>
f0101448:	68 92 3f 10 f0       	push   $0xf0103f92
f010144d:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101452:	68 c0 02 00 00       	push   $0x2c0
f0101457:	68 ad 3d 10 f0       	push   $0xf0103dad
f010145c:	e8 2a ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101461:	83 ec 0c             	sub    $0xc,%esp
f0101464:	57                   	push   %edi
f0101465:	e8 4b fa ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f010146a:	89 34 24             	mov    %esi,(%esp)
f010146d:	e8 43 fa ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f0101472:	83 c4 04             	add    $0x4,%esp
f0101475:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101478:	e8 38 fa ff ff       	call   f0100eb5 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010147d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101484:	e8 c2 f9 ff ff       	call   f0100e4b <page_alloc>
f0101489:	89 c6                	mov    %eax,%esi
f010148b:	83 c4 10             	add    $0x10,%esp
f010148e:	85 c0                	test   %eax,%eax
f0101490:	75 19                	jne    f01014ab <mem_init+0x300>
f0101492:	68 e7 3e 10 f0       	push   $0xf0103ee7
f0101497:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010149c:	68 c7 02 00 00       	push   $0x2c7
f01014a1:	68 ad 3d 10 f0       	push   $0xf0103dad
f01014a6:	e8 e0 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014ab:	83 ec 0c             	sub    $0xc,%esp
f01014ae:	6a 00                	push   $0x0
f01014b0:	e8 96 f9 ff ff       	call   f0100e4b <page_alloc>
f01014b5:	89 c7                	mov    %eax,%edi
f01014b7:	83 c4 10             	add    $0x10,%esp
f01014ba:	85 c0                	test   %eax,%eax
f01014bc:	75 19                	jne    f01014d7 <mem_init+0x32c>
f01014be:	68 fd 3e 10 f0       	push   $0xf0103efd
f01014c3:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01014c8:	68 c8 02 00 00       	push   $0x2c8
f01014cd:	68 ad 3d 10 f0       	push   $0xf0103dad
f01014d2:	e8 b4 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014d7:	83 ec 0c             	sub    $0xc,%esp
f01014da:	6a 00                	push   $0x0
f01014dc:	e8 6a f9 ff ff       	call   f0100e4b <page_alloc>
f01014e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014e4:	83 c4 10             	add    $0x10,%esp
f01014e7:	85 c0                	test   %eax,%eax
f01014e9:	75 19                	jne    f0101504 <mem_init+0x359>
f01014eb:	68 13 3f 10 f0       	push   $0xf0103f13
f01014f0:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01014f5:	68 c9 02 00 00       	push   $0x2c9
f01014fa:	68 ad 3d 10 f0       	push   $0xf0103dad
f01014ff:	e8 87 eb ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101504:	39 fe                	cmp    %edi,%esi
f0101506:	75 19                	jne    f0101521 <mem_init+0x376>
f0101508:	68 29 3f 10 f0       	push   $0xf0103f29
f010150d:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101512:	68 cb 02 00 00       	push   $0x2cb
f0101517:	68 ad 3d 10 f0       	push   $0xf0103dad
f010151c:	e8 6a eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101521:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101524:	39 c7                	cmp    %eax,%edi
f0101526:	74 04                	je     f010152c <mem_init+0x381>
f0101528:	39 c6                	cmp    %eax,%esi
f010152a:	75 19                	jne    f0101545 <mem_init+0x39a>
f010152c:	68 c0 42 10 f0       	push   $0xf01042c0
f0101531:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101536:	68 cc 02 00 00       	push   $0x2cc
f010153b:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101540:	e8 46 eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101545:	83 ec 0c             	sub    $0xc,%esp
f0101548:	6a 00                	push   $0x0
f010154a:	e8 fc f8 ff ff       	call   f0100e4b <page_alloc>
f010154f:	83 c4 10             	add    $0x10,%esp
f0101552:	85 c0                	test   %eax,%eax
f0101554:	74 19                	je     f010156f <mem_init+0x3c4>
f0101556:	68 92 3f 10 f0       	push   $0xf0103f92
f010155b:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101560:	68 cd 02 00 00       	push   $0x2cd
f0101565:	68 ad 3d 10 f0       	push   $0xf0103dad
f010156a:	e8 1c eb ff ff       	call   f010008b <_panic>
f010156f:	89 f0                	mov    %esi,%eax
f0101571:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101577:	c1 f8 03             	sar    $0x3,%eax
f010157a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010157d:	89 c2                	mov    %eax,%edx
f010157f:	c1 ea 0c             	shr    $0xc,%edx
f0101582:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101588:	72 12                	jb     f010159c <mem_init+0x3f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010158a:	50                   	push   %eax
f010158b:	68 30 41 10 f0       	push   $0xf0104130
f0101590:	6a 52                	push   $0x52
f0101592:	68 b9 3d 10 f0       	push   $0xf0103db9
f0101597:	e8 ef ea ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010159c:	83 ec 04             	sub    $0x4,%esp
f010159f:	68 00 10 00 00       	push   $0x1000
f01015a4:	6a 01                	push   $0x1
f01015a6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015ab:	50                   	push   %eax
f01015ac:	e8 34 1e 00 00       	call   f01033e5 <memset>
	page_free(pp0);
f01015b1:	89 34 24             	mov    %esi,(%esp)
f01015b4:	e8 fc f8 ff ff       	call   f0100eb5 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015b9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015c0:	e8 86 f8 ff ff       	call   f0100e4b <page_alloc>
f01015c5:	83 c4 10             	add    $0x10,%esp
f01015c8:	85 c0                	test   %eax,%eax
f01015ca:	75 19                	jne    f01015e5 <mem_init+0x43a>
f01015cc:	68 a1 3f 10 f0       	push   $0xf0103fa1
f01015d1:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01015d6:	68 d2 02 00 00       	push   $0x2d2
f01015db:	68 ad 3d 10 f0       	push   $0xf0103dad
f01015e0:	e8 a6 ea ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01015e5:	39 c6                	cmp    %eax,%esi
f01015e7:	74 19                	je     f0101602 <mem_init+0x457>
f01015e9:	68 bf 3f 10 f0       	push   $0xf0103fbf
f01015ee:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01015f3:	68 d3 02 00 00       	push   $0x2d3
f01015f8:	68 ad 3d 10 f0       	push   $0xf0103dad
f01015fd:	e8 89 ea ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101602:	89 f0                	mov    %esi,%eax
f0101604:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010160a:	c1 f8 03             	sar    $0x3,%eax
f010160d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101610:	89 c2                	mov    %eax,%edx
f0101612:	c1 ea 0c             	shr    $0xc,%edx
f0101615:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010161b:	72 12                	jb     f010162f <mem_init+0x484>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010161d:	50                   	push   %eax
f010161e:	68 30 41 10 f0       	push   $0xf0104130
f0101623:	6a 52                	push   $0x52
f0101625:	68 b9 3d 10 f0       	push   $0xf0103db9
f010162a:	e8 5c ea ff ff       	call   f010008b <_panic>
f010162f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101635:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010163b:	80 38 00             	cmpb   $0x0,(%eax)
f010163e:	74 19                	je     f0101659 <mem_init+0x4ae>
f0101640:	68 cf 3f 10 f0       	push   $0xf0103fcf
f0101645:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010164a:	68 d6 02 00 00       	push   $0x2d6
f010164f:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101654:	e8 32 ea ff ff       	call   f010008b <_panic>
f0101659:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010165c:	39 d0                	cmp    %edx,%eax
f010165e:	75 db                	jne    f010163b <mem_init+0x490>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101660:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101663:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101668:	83 ec 0c             	sub    $0xc,%esp
f010166b:	56                   	push   %esi
f010166c:	e8 44 f8 ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f0101671:	89 3c 24             	mov    %edi,(%esp)
f0101674:	e8 3c f8 ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f0101679:	83 c4 04             	add    $0x4,%esp
f010167c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010167f:	e8 31 f8 ff ff       	call   f0100eb5 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101684:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101689:	83 c4 10             	add    $0x10,%esp
f010168c:	eb 05                	jmp    f0101693 <mem_init+0x4e8>
		--nfree;
f010168e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101691:	8b 00                	mov    (%eax),%eax
f0101693:	85 c0                	test   %eax,%eax
f0101695:	75 f7                	jne    f010168e <mem_init+0x4e3>
		--nfree;
	assert(nfree == 0);
f0101697:	85 db                	test   %ebx,%ebx
f0101699:	74 19                	je     f01016b4 <mem_init+0x509>
f010169b:	68 d9 3f 10 f0       	push   $0xf0103fd9
f01016a0:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01016a5:	68 e3 02 00 00       	push   $0x2e3
f01016aa:	68 ad 3d 10 f0       	push   $0xf0103dad
f01016af:	e8 d7 e9 ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016b4:	83 ec 0c             	sub    $0xc,%esp
f01016b7:	68 e0 42 10 f0       	push   $0xf01042e0
f01016bc:	e8 3b 12 00 00       	call   f01028fc <cprintf>

// check page_insert, page_remove, &c
static void
check_page(void)
{
        cprintf("check\n");
f01016c1:	c7 04 24 e4 3f 10 f0 	movl   $0xf0103fe4,(%esp)
f01016c8:	e8 2f 12 00 00       	call   f01028fc <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d4:	e8 72 f7 ff ff       	call   f0100e4b <page_alloc>
f01016d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	85 c0                	test   %eax,%eax
f01016e1:	75 19                	jne    f01016fc <mem_init+0x551>
f01016e3:	68 e7 3e 10 f0       	push   $0xf0103ee7
f01016e8:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01016ed:	68 3d 03 00 00       	push   $0x33d
f01016f2:	68 ad 3d 10 f0       	push   $0xf0103dad
f01016f7:	e8 8f e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01016fc:	83 ec 0c             	sub    $0xc,%esp
f01016ff:	6a 00                	push   $0x0
f0101701:	e8 45 f7 ff ff       	call   f0100e4b <page_alloc>
f0101706:	89 c3                	mov    %eax,%ebx
f0101708:	83 c4 10             	add    $0x10,%esp
f010170b:	85 c0                	test   %eax,%eax
f010170d:	75 19                	jne    f0101728 <mem_init+0x57d>
f010170f:	68 fd 3e 10 f0       	push   $0xf0103efd
f0101714:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101719:	68 3e 03 00 00       	push   $0x33e
f010171e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101723:	e8 63 e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101728:	83 ec 0c             	sub    $0xc,%esp
f010172b:	6a 00                	push   $0x0
f010172d:	e8 19 f7 ff ff       	call   f0100e4b <page_alloc>
f0101732:	89 c6                	mov    %eax,%esi
f0101734:	83 c4 10             	add    $0x10,%esp
f0101737:	85 c0                	test   %eax,%eax
f0101739:	75 19                	jne    f0101754 <mem_init+0x5a9>
f010173b:	68 13 3f 10 f0       	push   $0xf0103f13
f0101740:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101745:	68 3f 03 00 00       	push   $0x33f
f010174a:	68 ad 3d 10 f0       	push   $0xf0103dad
f010174f:	e8 37 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101754:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101757:	75 19                	jne    f0101772 <mem_init+0x5c7>
f0101759:	68 29 3f 10 f0       	push   $0xf0103f29
f010175e:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101763:	68 42 03 00 00       	push   $0x342
f0101768:	68 ad 3d 10 f0       	push   $0xf0103dad
f010176d:	e8 19 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101772:	39 c3                	cmp    %eax,%ebx
f0101774:	74 05                	je     f010177b <mem_init+0x5d0>
f0101776:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101779:	75 19                	jne    f0101794 <mem_init+0x5e9>
f010177b:	68 c0 42 10 f0       	push   $0xf01042c0
f0101780:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101785:	68 43 03 00 00       	push   $0x343
f010178a:	68 ad 3d 10 f0       	push   $0xf0103dad
f010178f:	e8 f7 e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101794:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101799:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010179c:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01017a3:	00 00 00 
        cprintf("check\n");
f01017a6:	83 ec 0c             	sub    $0xc,%esp
f01017a9:	68 e4 3f 10 f0       	push   $0xf0103fe4
f01017ae:	e8 49 11 00 00       	call   f01028fc <cprintf>

	// should be no free memory
	assert(!page_alloc(0));
f01017b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ba:	e8 8c f6 ff ff       	call   f0100e4b <page_alloc>
f01017bf:	83 c4 10             	add    $0x10,%esp
f01017c2:	85 c0                	test   %eax,%eax
f01017c4:	74 19                	je     f01017df <mem_init+0x634>
f01017c6:	68 92 3f 10 f0       	push   $0xf0103f92
f01017cb:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01017d0:	68 4b 03 00 00       	push   $0x34b
f01017d5:	68 ad 3d 10 f0       	push   $0xf0103dad
f01017da:	e8 ac e8 ff ff       	call   f010008b <_panic>
        cprintf("check 123\n");
f01017df:	83 ec 0c             	sub    $0xc,%esp
f01017e2:	68 eb 3f 10 f0       	push   $0xf0103feb
f01017e7:	e8 10 11 00 00       	call   f01028fc <cprintf>
        cprintf("check %x\n", page_lookup(kern_pgdir, (void *) 0x0, &ptep));
f01017ec:	83 c4 0c             	add    $0xc,%esp
f01017ef:	8d 7d e4             	lea    -0x1c(%ebp),%edi
f01017f2:	57                   	push   %edi
f01017f3:	6a 00                	push   $0x0
f01017f5:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017fb:	e8 1e f8 ff ff       	call   f010101e <page_lookup>
f0101800:	83 c4 08             	add    $0x8,%esp
f0101803:	50                   	push   %eax
f0101804:	68 f6 3f 10 f0       	push   $0xf0103ff6
f0101809:	e8 ee 10 00 00       	call   f01028fc <cprintf>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010180e:	83 c4 0c             	add    $0xc,%esp
f0101811:	57                   	push   %edi
f0101812:	6a 00                	push   $0x0
f0101814:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010181a:	e8 ff f7 ff ff       	call   f010101e <page_lookup>
f010181f:	83 c4 10             	add    $0x10,%esp
f0101822:	85 c0                	test   %eax,%eax
f0101824:	74 19                	je     f010183f <mem_init+0x694>
f0101826:	68 00 43 10 f0       	push   $0xf0104300
f010182b:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101830:	68 50 03 00 00       	push   $0x350
f0101835:	68 ad 3d 10 f0       	push   $0xf0103dad
f010183a:	e8 4c e8 ff ff       	call   f010008b <_panic>
        cprintf("check yes...\n");
f010183f:	83 ec 0c             	sub    $0xc,%esp
f0101842:	68 00 40 10 f0       	push   $0xf0104000
f0101847:	e8 b0 10 00 00       	call   f01028fc <cprintf>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010184c:	6a 02                	push   $0x2
f010184e:	6a 00                	push   $0x0
f0101850:	53                   	push   %ebx
f0101851:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101857:	e8 7d f8 ff ff       	call   f01010d9 <page_insert>
f010185c:	83 c4 20             	add    $0x20,%esp
f010185f:	85 c0                	test   %eax,%eax
f0101861:	78 19                	js     f010187c <mem_init+0x6d1>
f0101863:	68 38 43 10 f0       	push   $0xf0104338
f0101868:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010186d:	68 54 03 00 00       	push   $0x354
f0101872:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101877:	e8 0f e8 ff ff       	call   f010008b <_panic>
        cprintf("insert done\n");
f010187c:	83 ec 0c             	sub    $0xc,%esp
f010187f:	68 0e 40 10 f0       	push   $0xf010400e
f0101884:	e8 73 10 00 00       	call   f01028fc <cprintf>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101889:	83 c4 04             	add    $0x4,%esp
f010188c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010188f:	e8 21 f6 ff ff       	call   f0100eb5 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101894:	6a 02                	push   $0x2
f0101896:	6a 00                	push   $0x0
f0101898:	53                   	push   %ebx
f0101899:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010189f:	e8 35 f8 ff ff       	call   f01010d9 <page_insert>
f01018a4:	83 c4 20             	add    $0x20,%esp
f01018a7:	85 c0                	test   %eax,%eax
f01018a9:	74 19                	je     f01018c4 <mem_init+0x719>
f01018ab:	68 68 43 10 f0       	push   $0xf0104368
f01018b0:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01018b5:	68 59 03 00 00       	push   $0x359
f01018ba:	68 ad 3d 10 f0       	push   $0xf0103dad
f01018bf:	e8 c7 e7 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018c4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018c9:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f01018cf:	8b 08                	mov    (%eax),%ecx
f01018d1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01018d7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01018da:	29 fa                	sub    %edi,%edx
f01018dc:	c1 fa 03             	sar    $0x3,%edx
f01018df:	c1 e2 0c             	shl    $0xc,%edx
f01018e2:	39 d1                	cmp    %edx,%ecx
f01018e4:	74 19                	je     f01018ff <mem_init+0x754>
f01018e6:	68 98 43 10 f0       	push   $0xf0104398
f01018eb:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01018f0:	68 5a 03 00 00       	push   $0x35a
f01018f5:	68 ad 3d 10 f0       	push   $0xf0103dad
f01018fa:	e8 8c e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101904:	e8 24 f1 ff ff       	call   f0100a2d <check_va2pa>
f0101909:	89 da                	mov    %ebx,%edx
f010190b:	29 fa                	sub    %edi,%edx
f010190d:	c1 fa 03             	sar    $0x3,%edx
f0101910:	c1 e2 0c             	shl    $0xc,%edx
f0101913:	39 d0                	cmp    %edx,%eax
f0101915:	74 19                	je     f0101930 <mem_init+0x785>
f0101917:	68 c0 43 10 f0       	push   $0xf01043c0
f010191c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101921:	68 5b 03 00 00       	push   $0x35b
f0101926:	68 ad 3d 10 f0       	push   $0xf0103dad
f010192b:	e8 5b e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101930:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101935:	74 19                	je     f0101950 <mem_init+0x7a5>
f0101937:	68 1b 40 10 f0       	push   $0xf010401b
f010193c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101941:	68 5c 03 00 00       	push   $0x35c
f0101946:	68 ad 3d 10 f0       	push   $0xf0103dad
f010194b:	e8 3b e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101950:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101953:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101958:	74 19                	je     f0101973 <mem_init+0x7c8>
f010195a:	68 2c 40 10 f0       	push   $0xf010402c
f010195f:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101964:	68 5d 03 00 00       	push   $0x35d
f0101969:	68 ad 3d 10 f0       	push   $0xf0103dad
f010196e:	e8 18 e7 ff ff       	call   f010008b <_panic>
        cprintf("insert done\n");
f0101973:	83 ec 0c             	sub    $0xc,%esp
f0101976:	68 0e 40 10 f0       	push   $0xf010400e
f010197b:	e8 7c 0f 00 00       	call   f01028fc <cprintf>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101980:	6a 02                	push   $0x2
f0101982:	68 00 10 00 00       	push   $0x1000
f0101987:	56                   	push   %esi
f0101988:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010198e:	e8 46 f7 ff ff       	call   f01010d9 <page_insert>
f0101993:	83 c4 20             	add    $0x20,%esp
f0101996:	85 c0                	test   %eax,%eax
f0101998:	74 19                	je     f01019b3 <mem_init+0x808>
f010199a:	68 f0 43 10 f0       	push   $0xf01043f0
f010199f:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01019a4:	68 61 03 00 00       	push   $0x361
f01019a9:	68 ad 3d 10 f0       	push   $0xf0103dad
f01019ae:	e8 d8 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019b8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019bd:	e8 6b f0 ff ff       	call   f0100a2d <check_va2pa>
f01019c2:	89 f2                	mov    %esi,%edx
f01019c4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019ca:	c1 fa 03             	sar    $0x3,%edx
f01019cd:	c1 e2 0c             	shl    $0xc,%edx
f01019d0:	39 d0                	cmp    %edx,%eax
f01019d2:	74 19                	je     f01019ed <mem_init+0x842>
f01019d4:	68 2c 44 10 f0       	push   $0xf010442c
f01019d9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01019de:	68 62 03 00 00       	push   $0x362
f01019e3:	68 ad 3d 10 f0       	push   $0xf0103dad
f01019e8:	e8 9e e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019ed:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019f2:	74 19                	je     f0101a0d <mem_init+0x862>
f01019f4:	68 3d 40 10 f0       	push   $0xf010403d
f01019f9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01019fe:	68 63 03 00 00       	push   $0x363
f0101a03:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101a08:	e8 7e e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a0d:	83 ec 0c             	sub    $0xc,%esp
f0101a10:	6a 00                	push   $0x0
f0101a12:	e8 34 f4 ff ff       	call   f0100e4b <page_alloc>
f0101a17:	83 c4 10             	add    $0x10,%esp
f0101a1a:	85 c0                	test   %eax,%eax
f0101a1c:	74 19                	je     f0101a37 <mem_init+0x88c>
f0101a1e:	68 92 3f 10 f0       	push   $0xf0103f92
f0101a23:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101a28:	68 66 03 00 00       	push   $0x366
f0101a2d:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101a32:	e8 54 e6 ff ff       	call   f010008b <_panic>
        cprintf("check_kern_pgdir() succeeded!\n");
f0101a37:	83 ec 0c             	sub    $0xc,%esp
f0101a3a:	68 5c 44 10 f0       	push   $0xf010445c
f0101a3f:	e8 b8 0e 00 00       	call   f01028fc <cprintf>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a44:	6a 02                	push   $0x2
f0101a46:	68 00 10 00 00       	push   $0x1000
f0101a4b:	56                   	push   %esi
f0101a4c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a52:	e8 82 f6 ff ff       	call   f01010d9 <page_insert>
f0101a57:	83 c4 20             	add    $0x20,%esp
f0101a5a:	85 c0                	test   %eax,%eax
f0101a5c:	74 19                	je     f0101a77 <mem_init+0x8cc>
f0101a5e:	68 f0 43 10 f0       	push   $0xf01043f0
f0101a63:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101a68:	68 6a 03 00 00       	push   $0x36a
f0101a6d:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101a72:	e8 14 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a77:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a7c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a81:	e8 a7 ef ff ff       	call   f0100a2d <check_va2pa>
f0101a86:	89 f2                	mov    %esi,%edx
f0101a88:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a8e:	c1 fa 03             	sar    $0x3,%edx
f0101a91:	c1 e2 0c             	shl    $0xc,%edx
f0101a94:	39 d0                	cmp    %edx,%eax
f0101a96:	74 19                	je     f0101ab1 <mem_init+0x906>
f0101a98:	68 2c 44 10 f0       	push   $0xf010442c
f0101a9d:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101aa2:	68 6b 03 00 00       	push   $0x36b
f0101aa7:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101aac:	e8 da e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101ab1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ab6:	74 19                	je     f0101ad1 <mem_init+0x926>
f0101ab8:	68 3d 40 10 f0       	push   $0xf010403d
f0101abd:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101ac2:	68 6c 03 00 00       	push   $0x36c
f0101ac7:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101acc:	e8 ba e5 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ad1:	83 ec 0c             	sub    $0xc,%esp
f0101ad4:	6a 00                	push   $0x0
f0101ad6:	e8 70 f3 ff ff       	call   f0100e4b <page_alloc>
f0101adb:	83 c4 10             	add    $0x10,%esp
f0101ade:	85 c0                	test   %eax,%eax
f0101ae0:	74 19                	je     f0101afb <mem_init+0x950>
f0101ae2:	68 92 3f 10 f0       	push   $0xf0103f92
f0101ae7:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101aec:	68 70 03 00 00       	push   $0x370
f0101af1:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101af6:	e8 90 e5 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101afb:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101b01:	8b 02                	mov    (%edx),%eax
f0101b03:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b08:	89 c1                	mov    %eax,%ecx
f0101b0a:	c1 e9 0c             	shr    $0xc,%ecx
f0101b0d:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101b13:	72 15                	jb     f0101b2a <mem_init+0x97f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b15:	50                   	push   %eax
f0101b16:	68 30 41 10 f0       	push   $0xf0104130
f0101b1b:	68 73 03 00 00       	push   $0x373
f0101b20:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101b25:	e8 61 e5 ff ff       	call   f010008b <_panic>
f0101b2a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b2f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b32:	83 ec 04             	sub    $0x4,%esp
f0101b35:	6a 00                	push   $0x0
f0101b37:	68 00 10 00 00       	push   $0x1000
f0101b3c:	52                   	push   %edx
f0101b3d:	e8 d2 f3 ff ff       	call   f0100f14 <pgdir_walk>
f0101b42:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b45:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b48:	83 c4 10             	add    $0x10,%esp
f0101b4b:	39 d0                	cmp    %edx,%eax
f0101b4d:	74 19                	je     f0101b68 <mem_init+0x9bd>
f0101b4f:	68 7c 44 10 f0       	push   $0xf010447c
f0101b54:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101b59:	68 74 03 00 00       	push   $0x374
f0101b5e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101b63:	e8 23 e5 ff ff       	call   f010008b <_panic>
        cprintf("check_kern_pgdir() succeeded!\n");
f0101b68:	83 ec 0c             	sub    $0xc,%esp
f0101b6b:	68 5c 44 10 f0       	push   $0xf010445c
f0101b70:	e8 87 0d 00 00       	call   f01028fc <cprintf>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b75:	6a 06                	push   $0x6
f0101b77:	68 00 10 00 00       	push   $0x1000
f0101b7c:	56                   	push   %esi
f0101b7d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b83:	e8 51 f5 ff ff       	call   f01010d9 <page_insert>
f0101b88:	83 c4 20             	add    $0x20,%esp
f0101b8b:	85 c0                	test   %eax,%eax
f0101b8d:	74 19                	je     f0101ba8 <mem_init+0x9fd>
f0101b8f:	68 bc 44 10 f0       	push   $0xf01044bc
f0101b94:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101b99:	68 78 03 00 00       	push   $0x378
f0101b9e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101ba3:	e8 e3 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ba8:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101bae:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb3:	89 f8                	mov    %edi,%eax
f0101bb5:	e8 73 ee ff ff       	call   f0100a2d <check_va2pa>
f0101bba:	89 f2                	mov    %esi,%edx
f0101bbc:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101bc2:	c1 fa 03             	sar    $0x3,%edx
f0101bc5:	c1 e2 0c             	shl    $0xc,%edx
f0101bc8:	39 d0                	cmp    %edx,%eax
f0101bca:	74 19                	je     f0101be5 <mem_init+0xa3a>
f0101bcc:	68 2c 44 10 f0       	push   $0xf010442c
f0101bd1:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101bd6:	68 79 03 00 00       	push   $0x379
f0101bdb:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101be0:	e8 a6 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101be5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bea:	74 19                	je     f0101c05 <mem_init+0xa5a>
f0101bec:	68 3d 40 10 f0       	push   $0xf010403d
f0101bf1:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101bf6:	68 7a 03 00 00       	push   $0x37a
f0101bfb:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101c00:	e8 86 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c05:	83 ec 04             	sub    $0x4,%esp
f0101c08:	6a 00                	push   $0x0
f0101c0a:	68 00 10 00 00       	push   $0x1000
f0101c0f:	57                   	push   %edi
f0101c10:	e8 ff f2 ff ff       	call   f0100f14 <pgdir_walk>
f0101c15:	83 c4 10             	add    $0x10,%esp
f0101c18:	f6 00 04             	testb  $0x4,(%eax)
f0101c1b:	75 19                	jne    f0101c36 <mem_init+0xa8b>
f0101c1d:	68 fc 44 10 f0       	push   $0xf01044fc
f0101c22:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101c27:	68 7b 03 00 00       	push   $0x37b
f0101c2c:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101c31:	e8 55 e4 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c36:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c3b:	f6 00 04             	testb  $0x4,(%eax)
f0101c3e:	75 19                	jne    f0101c59 <mem_init+0xaae>
f0101c40:	68 4e 40 10 f0       	push   $0xf010404e
f0101c45:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101c4a:	68 7c 03 00 00       	push   $0x37c
f0101c4f:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101c54:	e8 32 e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c59:	6a 02                	push   $0x2
f0101c5b:	68 00 10 00 00       	push   $0x1000
f0101c60:	56                   	push   %esi
f0101c61:	50                   	push   %eax
f0101c62:	e8 72 f4 ff ff       	call   f01010d9 <page_insert>
f0101c67:	83 c4 10             	add    $0x10,%esp
f0101c6a:	85 c0                	test   %eax,%eax
f0101c6c:	74 19                	je     f0101c87 <mem_init+0xadc>
f0101c6e:	68 f0 43 10 f0       	push   $0xf01043f0
f0101c73:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101c78:	68 7f 03 00 00       	push   $0x37f
f0101c7d:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101c82:	e8 04 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c87:	83 ec 04             	sub    $0x4,%esp
f0101c8a:	6a 00                	push   $0x0
f0101c8c:	68 00 10 00 00       	push   $0x1000
f0101c91:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c97:	e8 78 f2 ff ff       	call   f0100f14 <pgdir_walk>
f0101c9c:	83 c4 10             	add    $0x10,%esp
f0101c9f:	f6 00 02             	testb  $0x2,(%eax)
f0101ca2:	75 19                	jne    f0101cbd <mem_init+0xb12>
f0101ca4:	68 30 45 10 f0       	push   $0xf0104530
f0101ca9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101cae:	68 80 03 00 00       	push   $0x380
f0101cb3:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101cb8:	e8 ce e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cbd:	83 ec 04             	sub    $0x4,%esp
f0101cc0:	6a 00                	push   $0x0
f0101cc2:	68 00 10 00 00       	push   $0x1000
f0101cc7:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ccd:	e8 42 f2 ff ff       	call   f0100f14 <pgdir_walk>
f0101cd2:	83 c4 10             	add    $0x10,%esp
f0101cd5:	f6 00 04             	testb  $0x4,(%eax)
f0101cd8:	74 19                	je     f0101cf3 <mem_init+0xb48>
f0101cda:	68 64 45 10 f0       	push   $0xf0104564
f0101cdf:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101ce4:	68 81 03 00 00       	push   $0x381
f0101ce9:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101cee:	e8 98 e3 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101cf3:	6a 02                	push   $0x2
f0101cf5:	68 00 00 40 00       	push   $0x400000
f0101cfa:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cfd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d03:	e8 d1 f3 ff ff       	call   f01010d9 <page_insert>
f0101d08:	83 c4 10             	add    $0x10,%esp
f0101d0b:	85 c0                	test   %eax,%eax
f0101d0d:	78 19                	js     f0101d28 <mem_init+0xb7d>
f0101d0f:	68 9c 45 10 f0       	push   $0xf010459c
f0101d14:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101d19:	68 84 03 00 00       	push   $0x384
f0101d1e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101d23:	e8 63 e3 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d28:	6a 02                	push   $0x2
f0101d2a:	68 00 10 00 00       	push   $0x1000
f0101d2f:	53                   	push   %ebx
f0101d30:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d36:	e8 9e f3 ff ff       	call   f01010d9 <page_insert>
f0101d3b:	83 c4 10             	add    $0x10,%esp
f0101d3e:	85 c0                	test   %eax,%eax
f0101d40:	74 19                	je     f0101d5b <mem_init+0xbb0>
f0101d42:	68 d4 45 10 f0       	push   $0xf01045d4
f0101d47:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101d4c:	68 87 03 00 00       	push   $0x387
f0101d51:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101d56:	e8 30 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d5b:	83 ec 04             	sub    $0x4,%esp
f0101d5e:	6a 00                	push   $0x0
f0101d60:	68 00 10 00 00       	push   $0x1000
f0101d65:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d6b:	e8 a4 f1 ff ff       	call   f0100f14 <pgdir_walk>
f0101d70:	83 c4 10             	add    $0x10,%esp
f0101d73:	f6 00 04             	testb  $0x4,(%eax)
f0101d76:	74 19                	je     f0101d91 <mem_init+0xbe6>
f0101d78:	68 64 45 10 f0       	push   $0xf0104564
f0101d7d:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101d82:	68 88 03 00 00       	push   $0x388
f0101d87:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101d8c:	e8 fa e2 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d91:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d97:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d9c:	89 f8                	mov    %edi,%eax
f0101d9e:	e8 8a ec ff ff       	call   f0100a2d <check_va2pa>
f0101da3:	89 c1                	mov    %eax,%ecx
f0101da5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101da8:	89 d8                	mov    %ebx,%eax
f0101daa:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101db0:	c1 f8 03             	sar    $0x3,%eax
f0101db3:	c1 e0 0c             	shl    $0xc,%eax
f0101db6:	39 c1                	cmp    %eax,%ecx
f0101db8:	74 19                	je     f0101dd3 <mem_init+0xc28>
f0101dba:	68 10 46 10 f0       	push   $0xf0104610
f0101dbf:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101dc4:	68 8b 03 00 00       	push   $0x38b
f0101dc9:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101dce:	e8 b8 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dd3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd8:	89 f8                	mov    %edi,%eax
f0101dda:	e8 4e ec ff ff       	call   f0100a2d <check_va2pa>
f0101ddf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101de2:	74 19                	je     f0101dfd <mem_init+0xc52>
f0101de4:	68 3c 46 10 f0       	push   $0xf010463c
f0101de9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101dee:	68 8c 03 00 00       	push   $0x38c
f0101df3:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101df8:	e8 8e e2 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101dfd:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e02:	74 19                	je     f0101e1d <mem_init+0xc72>
f0101e04:	68 64 40 10 f0       	push   $0xf0104064
f0101e09:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101e0e:	68 8e 03 00 00       	push   $0x38e
f0101e13:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101e18:	e8 6e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e1d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e22:	74 19                	je     f0101e3d <mem_init+0xc92>
f0101e24:	68 75 40 10 f0       	push   $0xf0104075
f0101e29:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101e2e:	68 8f 03 00 00       	push   $0x38f
f0101e33:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>
        cprintf("check_kern_pgdir() succeeded!\n");
f0101e3d:	83 ec 0c             	sub    $0xc,%esp
f0101e40:	68 5c 44 10 f0       	push   $0xf010445c
f0101e45:	e8 b2 0a 00 00       	call   f01028fc <cprintf>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e51:	e8 f5 ef ff ff       	call   f0100e4b <page_alloc>
f0101e56:	83 c4 10             	add    $0x10,%esp
f0101e59:	85 c0                	test   %eax,%eax
f0101e5b:	74 04                	je     f0101e61 <mem_init+0xcb6>
f0101e5d:	39 c6                	cmp    %eax,%esi
f0101e5f:	74 19                	je     f0101e7a <mem_init+0xccf>
f0101e61:	68 6c 46 10 f0       	push   $0xf010466c
f0101e66:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101e6b:	68 93 03 00 00       	push   $0x393
f0101e70:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101e75:	e8 11 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e7a:	83 ec 08             	sub    $0x8,%esp
f0101e7d:	6a 00                	push   $0x0
f0101e7f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101e85:	e8 0c f2 ff ff       	call   f0101096 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e8a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e90:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e95:	89 f8                	mov    %edi,%eax
f0101e97:	e8 91 eb ff ff       	call   f0100a2d <check_va2pa>
f0101e9c:	83 c4 10             	add    $0x10,%esp
f0101e9f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea2:	74 19                	je     f0101ebd <mem_init+0xd12>
f0101ea4:	68 90 46 10 f0       	push   $0xf0104690
f0101ea9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101eae:	68 97 03 00 00       	push   $0x397
f0101eb3:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101eb8:	e8 ce e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ebd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec2:	89 f8                	mov    %edi,%eax
f0101ec4:	e8 64 eb ff ff       	call   f0100a2d <check_va2pa>
f0101ec9:	89 da                	mov    %ebx,%edx
f0101ecb:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101ed1:	c1 fa 03             	sar    $0x3,%edx
f0101ed4:	c1 e2 0c             	shl    $0xc,%edx
f0101ed7:	39 d0                	cmp    %edx,%eax
f0101ed9:	74 19                	je     f0101ef4 <mem_init+0xd49>
f0101edb:	68 3c 46 10 f0       	push   $0xf010463c
f0101ee0:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101ee5:	68 98 03 00 00       	push   $0x398
f0101eea:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101eef:	e8 97 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ef4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ef9:	74 19                	je     f0101f14 <mem_init+0xd69>
f0101efb:	68 1b 40 10 f0       	push   $0xf010401b
f0101f00:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101f05:	68 99 03 00 00       	push   $0x399
f0101f0a:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101f0f:	e8 77 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f14:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f19:	74 19                	je     f0101f34 <mem_init+0xd89>
f0101f1b:	68 75 40 10 f0       	push   $0xf0104075
f0101f20:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101f25:	68 9a 03 00 00       	push   $0x39a
f0101f2a:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101f2f:	e8 57 e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f34:	6a 00                	push   $0x0
f0101f36:	68 00 10 00 00       	push   $0x1000
f0101f3b:	53                   	push   %ebx
f0101f3c:	57                   	push   %edi
f0101f3d:	e8 97 f1 ff ff       	call   f01010d9 <page_insert>
f0101f42:	83 c4 10             	add    $0x10,%esp
f0101f45:	85 c0                	test   %eax,%eax
f0101f47:	74 19                	je     f0101f62 <mem_init+0xdb7>
f0101f49:	68 b4 46 10 f0       	push   $0xf01046b4
f0101f4e:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101f53:	68 9d 03 00 00       	push   $0x39d
f0101f58:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101f5d:	e8 29 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101f62:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f67:	75 19                	jne    f0101f82 <mem_init+0xdd7>
f0101f69:	68 86 40 10 f0       	push   $0xf0104086
f0101f6e:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101f73:	68 9e 03 00 00       	push   $0x39e
f0101f78:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101f7d:	e8 09 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101f82:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f85:	74 19                	je     f0101fa0 <mem_init+0xdf5>
f0101f87:	68 92 40 10 f0       	push   $0xf0104092
f0101f8c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101f91:	68 9f 03 00 00       	push   $0x39f
f0101f96:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101f9b:	e8 eb e0 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fa0:	83 ec 08             	sub    $0x8,%esp
f0101fa3:	68 00 10 00 00       	push   $0x1000
f0101fa8:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fae:	e8 e3 f0 ff ff       	call   f0101096 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fb3:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101fb9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fbe:	89 f8                	mov    %edi,%eax
f0101fc0:	e8 68 ea ff ff       	call   f0100a2d <check_va2pa>
f0101fc5:	83 c4 10             	add    $0x10,%esp
f0101fc8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fcb:	74 19                	je     f0101fe6 <mem_init+0xe3b>
f0101fcd:	68 90 46 10 f0       	push   $0xf0104690
f0101fd2:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0101fd7:	68 a3 03 00 00       	push   $0x3a3
f0101fdc:	68 ad 3d 10 f0       	push   $0xf0103dad
f0101fe1:	e8 a5 e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fe6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101feb:	89 f8                	mov    %edi,%eax
f0101fed:	e8 3b ea ff ff       	call   f0100a2d <check_va2pa>
f0101ff2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ff5:	74 19                	je     f0102010 <mem_init+0xe65>
f0101ff7:	68 ec 46 10 f0       	push   $0xf01046ec
f0101ffc:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102001:	68 a4 03 00 00       	push   $0x3a4
f0102006:	68 ad 3d 10 f0       	push   $0xf0103dad
f010200b:	e8 7b e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102010:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102015:	74 19                	je     f0102030 <mem_init+0xe85>
f0102017:	68 a7 40 10 f0       	push   $0xf01040a7
f010201c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102021:	68 a5 03 00 00       	push   $0x3a5
f0102026:	68 ad 3d 10 f0       	push   $0xf0103dad
f010202b:	e8 5b e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0102030:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102035:	74 19                	je     f0102050 <mem_init+0xea5>
f0102037:	68 75 40 10 f0       	push   $0xf0104075
f010203c:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102041:	68 a6 03 00 00       	push   $0x3a6
f0102046:	68 ad 3d 10 f0       	push   $0xf0103dad
f010204b:	e8 3b e0 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102050:	83 ec 0c             	sub    $0xc,%esp
f0102053:	6a 00                	push   $0x0
f0102055:	e8 f1 ed ff ff       	call   f0100e4b <page_alloc>
f010205a:	83 c4 10             	add    $0x10,%esp
f010205d:	39 c3                	cmp    %eax,%ebx
f010205f:	75 04                	jne    f0102065 <mem_init+0xeba>
f0102061:	85 c0                	test   %eax,%eax
f0102063:	75 19                	jne    f010207e <mem_init+0xed3>
f0102065:	68 14 47 10 f0       	push   $0xf0104714
f010206a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010206f:	68 a9 03 00 00       	push   $0x3a9
f0102074:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102079:	e8 0d e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010207e:	83 ec 0c             	sub    $0xc,%esp
f0102081:	6a 00                	push   $0x0
f0102083:	e8 c3 ed ff ff       	call   f0100e4b <page_alloc>
f0102088:	83 c4 10             	add    $0x10,%esp
f010208b:	85 c0                	test   %eax,%eax
f010208d:	74 19                	je     f01020a8 <mem_init+0xefd>
f010208f:	68 92 3f 10 f0       	push   $0xf0103f92
f0102094:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102099:	68 ac 03 00 00       	push   $0x3ac
f010209e:	68 ad 3d 10 f0       	push   $0xf0103dad
f01020a3:	e8 e3 df ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01020a8:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01020ae:	8b 11                	mov    (%ecx),%edx
f01020b0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01020b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01020bf:	c1 f8 03             	sar    $0x3,%eax
f01020c2:	c1 e0 0c             	shl    $0xc,%eax
f01020c5:	39 c2                	cmp    %eax,%edx
f01020c7:	74 19                	je     f01020e2 <mem_init+0xf37>
f01020c9:	68 98 43 10 f0       	push   $0xf0104398
f01020ce:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01020d3:	68 af 03 00 00       	push   $0x3af
f01020d8:	68 ad 3d 10 f0       	push   $0xf0103dad
f01020dd:	e8 a9 df ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01020e2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020eb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020f0:	74 19                	je     f010210b <mem_init+0xf60>
f01020f2:	68 2c 40 10 f0       	push   $0xf010402c
f01020f7:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01020fc:	68 b1 03 00 00       	push   $0x3b1
f0102101:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102106:	e8 80 df ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010210b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010210e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
        cprintf("check_kern_pgdir() succeeded!\n");
f0102114:	83 ec 0c             	sub    $0xc,%esp
f0102117:	68 5c 44 10 f0       	push   $0xf010445c
f010211c:	e8 db 07 00 00       	call   f01028fc <cprintf>

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102121:	89 3c 24             	mov    %edi,(%esp)
f0102124:	e8 8c ed ff ff       	call   f0100eb5 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102129:	83 c4 0c             	add    $0xc,%esp
f010212c:	6a 01                	push   $0x1
f010212e:	68 00 10 40 00       	push   $0x401000
f0102133:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102139:	e8 d6 ed ff ff       	call   f0100f14 <pgdir_walk>
f010213e:	89 c7                	mov    %eax,%edi
f0102140:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102143:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102148:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010214b:	8b 40 04             	mov    0x4(%eax),%eax
f010214e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102153:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0102159:	89 c2                	mov    %eax,%edx
f010215b:	c1 ea 0c             	shr    $0xc,%edx
f010215e:	83 c4 10             	add    $0x10,%esp
f0102161:	39 ca                	cmp    %ecx,%edx
f0102163:	72 15                	jb     f010217a <mem_init+0xfcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102165:	50                   	push   %eax
f0102166:	68 30 41 10 f0       	push   $0xf0104130
f010216b:	68 b9 03 00 00       	push   $0x3b9
f0102170:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102175:	e8 11 df ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f010217a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010217f:	39 c7                	cmp    %eax,%edi
f0102181:	74 19                	je     f010219c <mem_init+0xff1>
f0102183:	68 b8 40 10 f0       	push   $0xf01040b8
f0102188:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010218d:	68 ba 03 00 00       	push   $0x3ba
f0102192:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102197:	e8 ef de ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010219c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010219f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01021a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021a9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021af:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01021b5:	c1 f8 03             	sar    $0x3,%eax
f01021b8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021bb:	89 c2                	mov    %eax,%edx
f01021bd:	c1 ea 0c             	shr    $0xc,%edx
f01021c0:	39 d1                	cmp    %edx,%ecx
f01021c2:	77 12                	ja     f01021d6 <mem_init+0x102b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021c4:	50                   	push   %eax
f01021c5:	68 30 41 10 f0       	push   $0xf0104130
f01021ca:	6a 52                	push   $0x52
f01021cc:	68 b9 3d 10 f0       	push   $0xf0103db9
f01021d1:	e8 b5 de ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021d6:	83 ec 04             	sub    $0x4,%esp
f01021d9:	68 00 10 00 00       	push   $0x1000
f01021de:	68 ff 00 00 00       	push   $0xff
f01021e3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01021e8:	50                   	push   %eax
f01021e9:	e8 f7 11 00 00       	call   f01033e5 <memset>
	page_free(pp0);
f01021ee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021f1:	89 3c 24             	mov    %edi,(%esp)
f01021f4:	e8 bc ec ff ff       	call   f0100eb5 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021f9:	83 c4 0c             	add    $0xc,%esp
f01021fc:	6a 01                	push   $0x1
f01021fe:	6a 00                	push   $0x0
f0102200:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102206:	e8 09 ed ff ff       	call   f0100f14 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010220b:	89 fa                	mov    %edi,%edx
f010220d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102213:	c1 fa 03             	sar    $0x3,%edx
f0102216:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102219:	89 d0                	mov    %edx,%eax
f010221b:	c1 e8 0c             	shr    $0xc,%eax
f010221e:	83 c4 10             	add    $0x10,%esp
f0102221:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102227:	72 12                	jb     f010223b <mem_init+0x1090>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102229:	52                   	push   %edx
f010222a:	68 30 41 10 f0       	push   $0xf0104130
f010222f:	6a 52                	push   $0x52
f0102231:	68 b9 3d 10 f0       	push   $0xf0103db9
f0102236:	e8 50 de ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010223b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102241:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102244:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010224a:	f6 00 01             	testb  $0x1,(%eax)
f010224d:	74 19                	je     f0102268 <mem_init+0x10bd>
f010224f:	68 d0 40 10 f0       	push   $0xf01040d0
f0102254:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102259:	68 c4 03 00 00       	push   $0x3c4
f010225e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102263:	e8 23 de ff ff       	call   f010008b <_panic>
f0102268:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010226b:	39 d0                	cmp    %edx,%eax
f010226d:	75 db                	jne    f010224a <mem_init+0x109f>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010226f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102274:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010227a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102283:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102286:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010228c:	83 ec 0c             	sub    $0xc,%esp
f010228f:	50                   	push   %eax
f0102290:	e8 20 ec ff ff       	call   f0100eb5 <page_free>
	page_free(pp1);
f0102295:	89 1c 24             	mov    %ebx,(%esp)
f0102298:	e8 18 ec ff ff       	call   f0100eb5 <page_free>
	page_free(pp2);
f010229d:	89 34 24             	mov    %esi,(%esp)
f01022a0:	e8 10 ec ff ff       	call   f0100eb5 <page_free>

	cprintf("check_page() succeeded!\n");
f01022a5:	c7 04 24 e7 40 10 f0 	movl   $0xf01040e7,(%esp)
f01022ac:	e8 4b 06 00 00       	call   f01028fc <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01022b1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022b6:	83 c4 10             	add    $0x10,%esp
f01022b9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022be:	77 15                	ja     f01022d5 <mem_init+0x112a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022c0:	50                   	push   %eax
f01022c1:	68 9c 42 10 f0       	push   $0xf010429c
f01022c6:	68 c4 00 00 00       	push   $0xc4
f01022cb:	68 ad 3d 10 f0       	push   $0xf0103dad
f01022d0:	e8 b6 dd ff ff       	call   f010008b <_panic>
f01022d5:	83 ec 08             	sub    $0x8,%esp
f01022d8:	6a 04                	push   $0x4
f01022da:	05 00 00 00 10       	add    $0x10000000,%eax
f01022df:	50                   	push   %eax
f01022e0:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01022e5:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01022ea:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01022ef:	e8 b3 ec ff ff       	call   f0100fa7 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022f4:	83 c4 10             	add    $0x10,%esp
f01022f7:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01022fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102301:	77 15                	ja     f0102318 <mem_init+0x116d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102303:	50                   	push   %eax
f0102304:	68 9c 42 10 f0       	push   $0xf010429c
f0102309:	68 d1 00 00 00       	push   $0xd1
f010230e:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102313:	e8 73 dd ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102318:	83 ec 08             	sub    $0x8,%esp
f010231b:	6a 02                	push   $0x2
f010231d:	68 00 d0 10 00       	push   $0x10d000
f0102322:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102327:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010232c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102331:	e8 71 ec ff ff       	call   f0100fa7 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102336:	83 c4 08             	add    $0x8,%esp
f0102339:	6a 02                	push   $0x2
f010233b:	6a 00                	push   $0x0
f010233d:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102342:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102347:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010234c:	e8 56 ec ff ff       	call   f0100fa7 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102351:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102357:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010235c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010235f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102366:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010236b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010236e:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102374:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102377:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010237a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010237f:	eb 55                	jmp    f01023d6 <mem_init+0x122b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102381:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102387:	89 f0                	mov    %esi,%eax
f0102389:	e8 9f e6 ff ff       	call   f0100a2d <check_va2pa>
f010238e:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102395:	77 15                	ja     f01023ac <mem_init+0x1201>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102397:	57                   	push   %edi
f0102398:	68 9c 42 10 f0       	push   $0xf010429c
f010239d:	68 fb 02 00 00       	push   $0x2fb
f01023a2:	68 ad 3d 10 f0       	push   $0xf0103dad
f01023a7:	e8 df dc ff ff       	call   f010008b <_panic>
f01023ac:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01023b3:	39 c2                	cmp    %eax,%edx
f01023b5:	74 19                	je     f01023d0 <mem_init+0x1225>
f01023b7:	68 38 47 10 f0       	push   $0xf0104738
f01023bc:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01023c1:	68 fb 02 00 00       	push   $0x2fb
f01023c6:	68 ad 3d 10 f0       	push   $0xf0103dad
f01023cb:	e8 bb dc ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01023d0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01023d6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01023d9:	77 a6                	ja     f0102381 <mem_init+0x11d6>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023db:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01023de:	c1 e7 0c             	shl    $0xc,%edi
f01023e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01023e6:	eb 30                	jmp    f0102418 <mem_init+0x126d>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01023e8:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01023ee:	89 f0                	mov    %esi,%eax
f01023f0:	e8 38 e6 ff ff       	call   f0100a2d <check_va2pa>
f01023f5:	39 c3                	cmp    %eax,%ebx
f01023f7:	74 19                	je     f0102412 <mem_init+0x1267>
f01023f9:	68 6c 47 10 f0       	push   $0xf010476c
f01023fe:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102403:	68 00 03 00 00       	push   $0x300
f0102408:	68 ad 3d 10 f0       	push   $0xf0103dad
f010240d:	e8 79 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102412:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102418:	39 fb                	cmp    %edi,%ebx
f010241a:	72 cc                	jb     f01023e8 <mem_init+0x123d>
f010241c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102421:	89 da                	mov    %ebx,%edx
f0102423:	89 f0                	mov    %esi,%eax
f0102425:	e8 03 e6 ff ff       	call   f0100a2d <check_va2pa>
f010242a:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102430:	39 c2                	cmp    %eax,%edx
f0102432:	74 19                	je     f010244d <mem_init+0x12a2>
f0102434:	68 94 47 10 f0       	push   $0xf0104794
f0102439:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010243e:	68 04 03 00 00       	push   $0x304
f0102443:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102448:	e8 3e dc ff ff       	call   f010008b <_panic>
f010244d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102453:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102459:	75 c6                	jne    f0102421 <mem_init+0x1276>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010245b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102460:	89 f0                	mov    %esi,%eax
f0102462:	e8 c6 e5 ff ff       	call   f0100a2d <check_va2pa>
f0102467:	83 f8 ff             	cmp    $0xffffffff,%eax
f010246a:	74 51                	je     f01024bd <mem_init+0x1312>
f010246c:	68 dc 47 10 f0       	push   $0xf01047dc
f0102471:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102476:	68 05 03 00 00       	push   $0x305
f010247b:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102480:	e8 06 dc ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102485:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010248a:	72 36                	jb     f01024c2 <mem_init+0x1317>
f010248c:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102491:	76 07                	jbe    f010249a <mem_init+0x12ef>
f0102493:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102498:	75 28                	jne    f01024c2 <mem_init+0x1317>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010249a:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010249e:	0f 85 83 00 00 00    	jne    f0102527 <mem_init+0x137c>
f01024a4:	68 00 41 10 f0       	push   $0xf0104100
f01024a9:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01024ae:	68 0d 03 00 00       	push   $0x30d
f01024b3:	68 ad 3d 10 f0       	push   $0xf0103dad
f01024b8:	e8 ce db ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01024bd:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01024c2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01024c7:	76 3f                	jbe    f0102508 <mem_init+0x135d>
				assert(pgdir[i] & PTE_P);
f01024c9:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01024cc:	f6 c2 01             	test   $0x1,%dl
f01024cf:	75 19                	jne    f01024ea <mem_init+0x133f>
f01024d1:	68 00 41 10 f0       	push   $0xf0104100
f01024d6:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01024db:	68 11 03 00 00       	push   $0x311
f01024e0:	68 ad 3d 10 f0       	push   $0xf0103dad
f01024e5:	e8 a1 db ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01024ea:	f6 c2 02             	test   $0x2,%dl
f01024ed:	75 38                	jne    f0102527 <mem_init+0x137c>
f01024ef:	68 11 41 10 f0       	push   $0xf0104111
f01024f4:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01024f9:	68 12 03 00 00       	push   $0x312
f01024fe:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102503:	e8 83 db ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102508:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010250c:	74 19                	je     f0102527 <mem_init+0x137c>
f010250e:	68 22 41 10 f0       	push   $0xf0104122
f0102513:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102518:	68 14 03 00 00       	push   $0x314
f010251d:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102522:	e8 64 db ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102527:	83 c0 01             	add    $0x1,%eax
f010252a:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010252f:	0f 86 50 ff ff ff    	jbe    f0102485 <mem_init+0x12da>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102535:	83 ec 0c             	sub    $0xc,%esp
f0102538:	68 5c 44 10 f0       	push   $0xf010445c
f010253d:	e8 ba 03 00 00       	call   f01028fc <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102542:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102547:	83 c4 10             	add    $0x10,%esp
f010254a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010254f:	77 15                	ja     f0102566 <mem_init+0x13bb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102551:	50                   	push   %eax
f0102552:	68 9c 42 10 f0       	push   $0xf010429c
f0102557:	68 e7 00 00 00       	push   $0xe7
f010255c:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102561:	e8 25 db ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102566:	05 00 00 00 10       	add    $0x10000000,%eax
f010256b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010256e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102573:	e8 19 e5 ff ff       	call   f0100a91 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102578:	0f 20 c0             	mov    %cr0,%eax
f010257b:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010257e:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102583:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102586:	83 ec 0c             	sub    $0xc,%esp
f0102589:	6a 00                	push   $0x0
f010258b:	e8 bb e8 ff ff       	call   f0100e4b <page_alloc>
f0102590:	89 c3                	mov    %eax,%ebx
f0102592:	83 c4 10             	add    $0x10,%esp
f0102595:	85 c0                	test   %eax,%eax
f0102597:	75 19                	jne    f01025b2 <mem_init+0x1407>
f0102599:	68 e7 3e 10 f0       	push   $0xf0103ee7
f010259e:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01025a3:	68 df 03 00 00       	push   $0x3df
f01025a8:	68 ad 3d 10 f0       	push   $0xf0103dad
f01025ad:	e8 d9 da ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01025b2:	83 ec 0c             	sub    $0xc,%esp
f01025b5:	6a 00                	push   $0x0
f01025b7:	e8 8f e8 ff ff       	call   f0100e4b <page_alloc>
f01025bc:	89 c7                	mov    %eax,%edi
f01025be:	83 c4 10             	add    $0x10,%esp
f01025c1:	85 c0                	test   %eax,%eax
f01025c3:	75 19                	jne    f01025de <mem_init+0x1433>
f01025c5:	68 fd 3e 10 f0       	push   $0xf0103efd
f01025ca:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01025cf:	68 e0 03 00 00       	push   $0x3e0
f01025d4:	68 ad 3d 10 f0       	push   $0xf0103dad
f01025d9:	e8 ad da ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01025de:	83 ec 0c             	sub    $0xc,%esp
f01025e1:	6a 00                	push   $0x0
f01025e3:	e8 63 e8 ff ff       	call   f0100e4b <page_alloc>
f01025e8:	89 c6                	mov    %eax,%esi
f01025ea:	83 c4 10             	add    $0x10,%esp
f01025ed:	85 c0                	test   %eax,%eax
f01025ef:	75 19                	jne    f010260a <mem_init+0x145f>
f01025f1:	68 13 3f 10 f0       	push   $0xf0103f13
f01025f6:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01025fb:	68 e1 03 00 00       	push   $0x3e1
f0102600:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102605:	e8 81 da ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010260a:	83 ec 0c             	sub    $0xc,%esp
f010260d:	53                   	push   %ebx
f010260e:	e8 a2 e8 ff ff       	call   f0100eb5 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102613:	89 f8                	mov    %edi,%eax
f0102615:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010261b:	c1 f8 03             	sar    $0x3,%eax
f010261e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102621:	89 c2                	mov    %eax,%edx
f0102623:	c1 ea 0c             	shr    $0xc,%edx
f0102626:	83 c4 10             	add    $0x10,%esp
f0102629:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010262f:	72 12                	jb     f0102643 <mem_init+0x1498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102631:	50                   	push   %eax
f0102632:	68 30 41 10 f0       	push   $0xf0104130
f0102637:	6a 52                	push   $0x52
f0102639:	68 b9 3d 10 f0       	push   $0xf0103db9
f010263e:	e8 48 da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102643:	83 ec 04             	sub    $0x4,%esp
f0102646:	68 00 10 00 00       	push   $0x1000
f010264b:	6a 01                	push   $0x1
f010264d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102652:	50                   	push   %eax
f0102653:	e8 8d 0d 00 00       	call   f01033e5 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102658:	89 f0                	mov    %esi,%eax
f010265a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102660:	c1 f8 03             	sar    $0x3,%eax
f0102663:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102666:	89 c2                	mov    %eax,%edx
f0102668:	c1 ea 0c             	shr    $0xc,%edx
f010266b:	83 c4 10             	add    $0x10,%esp
f010266e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102674:	72 12                	jb     f0102688 <mem_init+0x14dd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102676:	50                   	push   %eax
f0102677:	68 30 41 10 f0       	push   $0xf0104130
f010267c:	6a 52                	push   $0x52
f010267e:	68 b9 3d 10 f0       	push   $0xf0103db9
f0102683:	e8 03 da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102688:	83 ec 04             	sub    $0x4,%esp
f010268b:	68 00 10 00 00       	push   $0x1000
f0102690:	6a 02                	push   $0x2
f0102692:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102697:	50                   	push   %eax
f0102698:	e8 48 0d 00 00       	call   f01033e5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010269d:	6a 02                	push   $0x2
f010269f:	68 00 10 00 00       	push   $0x1000
f01026a4:	57                   	push   %edi
f01026a5:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01026ab:	e8 29 ea ff ff       	call   f01010d9 <page_insert>
	assert(pp1->pp_ref == 1);
f01026b0:	83 c4 20             	add    $0x20,%esp
f01026b3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01026b8:	74 19                	je     f01026d3 <mem_init+0x1528>
f01026ba:	68 1b 40 10 f0       	push   $0xf010401b
f01026bf:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01026c4:	68 e6 03 00 00       	push   $0x3e6
f01026c9:	68 ad 3d 10 f0       	push   $0xf0103dad
f01026ce:	e8 b8 d9 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01026d3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01026da:	01 01 01 
f01026dd:	74 19                	je     f01026f8 <mem_init+0x154d>
f01026df:	68 0c 48 10 f0       	push   $0xf010480c
f01026e4:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01026e9:	68 e7 03 00 00       	push   $0x3e7
f01026ee:	68 ad 3d 10 f0       	push   $0xf0103dad
f01026f3:	e8 93 d9 ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01026f8:	6a 02                	push   $0x2
f01026fa:	68 00 10 00 00       	push   $0x1000
f01026ff:	56                   	push   %esi
f0102700:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102706:	e8 ce e9 ff ff       	call   f01010d9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010270b:	83 c4 10             	add    $0x10,%esp
f010270e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102715:	02 02 02 
f0102718:	74 19                	je     f0102733 <mem_init+0x1588>
f010271a:	68 30 48 10 f0       	push   $0xf0104830
f010271f:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102724:	68 e9 03 00 00       	push   $0x3e9
f0102729:	68 ad 3d 10 f0       	push   $0xf0103dad
f010272e:	e8 58 d9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102733:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102738:	74 19                	je     f0102753 <mem_init+0x15a8>
f010273a:	68 3d 40 10 f0       	push   $0xf010403d
f010273f:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102744:	68 ea 03 00 00       	push   $0x3ea
f0102749:	68 ad 3d 10 f0       	push   $0xf0103dad
f010274e:	e8 38 d9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102753:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102758:	74 19                	je     f0102773 <mem_init+0x15c8>
f010275a:	68 a7 40 10 f0       	push   $0xf01040a7
f010275f:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102764:	68 eb 03 00 00       	push   $0x3eb
f0102769:	68 ad 3d 10 f0       	push   $0xf0103dad
f010276e:	e8 18 d9 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102773:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010277a:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010277d:	89 f0                	mov    %esi,%eax
f010277f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102785:	c1 f8 03             	sar    $0x3,%eax
f0102788:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010278b:	89 c2                	mov    %eax,%edx
f010278d:	c1 ea 0c             	shr    $0xc,%edx
f0102790:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102796:	72 12                	jb     f01027aa <mem_init+0x15ff>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102798:	50                   	push   %eax
f0102799:	68 30 41 10 f0       	push   $0xf0104130
f010279e:	6a 52                	push   $0x52
f01027a0:	68 b9 3d 10 f0       	push   $0xf0103db9
f01027a5:	e8 e1 d8 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01027aa:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01027b1:	03 03 03 
f01027b4:	74 19                	je     f01027cf <mem_init+0x1624>
f01027b6:	68 54 48 10 f0       	push   $0xf0104854
f01027bb:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01027c0:	68 ed 03 00 00       	push   $0x3ed
f01027c5:	68 ad 3d 10 f0       	push   $0xf0103dad
f01027ca:	e8 bc d8 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01027cf:	83 ec 08             	sub    $0x8,%esp
f01027d2:	68 00 10 00 00       	push   $0x1000
f01027d7:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01027dd:	e8 b4 e8 ff ff       	call   f0101096 <page_remove>
	assert(pp2->pp_ref == 0);
f01027e2:	83 c4 10             	add    $0x10,%esp
f01027e5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027ea:	74 19                	je     f0102805 <mem_init+0x165a>
f01027ec:	68 75 40 10 f0       	push   $0xf0104075
f01027f1:	68 d3 3d 10 f0       	push   $0xf0103dd3
f01027f6:	68 ef 03 00 00       	push   $0x3ef
f01027fb:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102800:	e8 86 d8 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102805:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f010280b:	8b 11                	mov    (%ecx),%edx
f010280d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102813:	89 d8                	mov    %ebx,%eax
f0102815:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010281b:	c1 f8 03             	sar    $0x3,%eax
f010281e:	c1 e0 0c             	shl    $0xc,%eax
f0102821:	39 c2                	cmp    %eax,%edx
f0102823:	74 19                	je     f010283e <mem_init+0x1693>
f0102825:	68 98 43 10 f0       	push   $0xf0104398
f010282a:	68 d3 3d 10 f0       	push   $0xf0103dd3
f010282f:	68 f2 03 00 00       	push   $0x3f2
f0102834:	68 ad 3d 10 f0       	push   $0xf0103dad
f0102839:	e8 4d d8 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010283e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102844:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102849:	74 19                	je     f0102864 <mem_init+0x16b9>
f010284b:	68 2c 40 10 f0       	push   $0xf010402c
f0102850:	68 d3 3d 10 f0       	push   $0xf0103dd3
f0102855:	68 f4 03 00 00       	push   $0x3f4
f010285a:	68 ad 3d 10 f0       	push   $0xf0103dad
f010285f:	e8 27 d8 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102864:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010286a:	83 ec 0c             	sub    $0xc,%esp
f010286d:	53                   	push   %ebx
f010286e:	e8 42 e6 ff ff       	call   f0100eb5 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102873:	c7 04 24 80 48 10 f0 	movl   $0xf0104880,(%esp)
f010287a:	e8 7d 00 00 00       	call   f01028fc <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010287f:	83 c4 10             	add    $0x10,%esp
f0102882:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102885:	5b                   	pop    %ebx
f0102886:	5e                   	pop    %esi
f0102887:	5f                   	pop    %edi
f0102888:	5d                   	pop    %ebp
f0102889:	c3                   	ret    

f010288a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010288a:	55                   	push   %ebp
f010288b:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010288d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102890:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102893:	5d                   	pop    %ebp
f0102894:	c3                   	ret    

f0102895 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102895:	55                   	push   %ebp
f0102896:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102898:	ba 70 00 00 00       	mov    $0x70,%edx
f010289d:	8b 45 08             	mov    0x8(%ebp),%eax
f01028a0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01028a1:	ba 71 00 00 00       	mov    $0x71,%edx
f01028a6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01028a7:	0f b6 c0             	movzbl %al,%eax
}
f01028aa:	5d                   	pop    %ebp
f01028ab:	c3                   	ret    

f01028ac <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01028ac:	55                   	push   %ebp
f01028ad:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01028af:	ba 70 00 00 00       	mov    $0x70,%edx
f01028b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01028b7:	ee                   	out    %al,(%dx)
f01028b8:	ba 71 00 00 00       	mov    $0x71,%edx
f01028bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028c0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01028c1:	5d                   	pop    %ebp
f01028c2:	c3                   	ret    

f01028c3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01028c3:	55                   	push   %ebp
f01028c4:	89 e5                	mov    %esp,%ebp
f01028c6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01028c9:	ff 75 08             	pushl  0x8(%ebp)
f01028cc:	e8 2f dd ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01028d1:	83 c4 10             	add    $0x10,%esp
f01028d4:	c9                   	leave  
f01028d5:	c3                   	ret    

f01028d6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01028d6:	55                   	push   %ebp
f01028d7:	89 e5                	mov    %esp,%ebp
f01028d9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01028dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01028e3:	ff 75 0c             	pushl  0xc(%ebp)
f01028e6:	ff 75 08             	pushl  0x8(%ebp)
f01028e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01028ec:	50                   	push   %eax
f01028ed:	68 c3 28 10 f0       	push   $0xf01028c3
f01028f2:	e8 c9 03 00 00       	call   f0102cc0 <vprintfmt>
	return cnt;
}
f01028f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01028fa:	c9                   	leave  
f01028fb:	c3                   	ret    

f01028fc <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01028fc:	55                   	push   %ebp
f01028fd:	89 e5                	mov    %esp,%ebp
f01028ff:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102902:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102905:	50                   	push   %eax
f0102906:	ff 75 08             	pushl  0x8(%ebp)
f0102909:	e8 c8 ff ff ff       	call   f01028d6 <vcprintf>
	va_end(ap);

	return cnt;
}
f010290e:	c9                   	leave  
f010290f:	c3                   	ret    

f0102910 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102910:	55                   	push   %ebp
f0102911:	89 e5                	mov    %esp,%ebp
f0102913:	57                   	push   %edi
f0102914:	56                   	push   %esi
f0102915:	53                   	push   %ebx
f0102916:	83 ec 14             	sub    $0x14,%esp
f0102919:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010291c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010291f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102922:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102925:	8b 1a                	mov    (%edx),%ebx
f0102927:	8b 01                	mov    (%ecx),%eax
f0102929:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010292c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102933:	eb 7f                	jmp    f01029b4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102935:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102938:	01 d8                	add    %ebx,%eax
f010293a:	89 c6                	mov    %eax,%esi
f010293c:	c1 ee 1f             	shr    $0x1f,%esi
f010293f:	01 c6                	add    %eax,%esi
f0102941:	d1 fe                	sar    %esi
f0102943:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102946:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102949:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010294c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010294e:	eb 03                	jmp    f0102953 <stab_binsearch+0x43>
			m--;
f0102950:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102953:	39 c3                	cmp    %eax,%ebx
f0102955:	7f 0d                	jg     f0102964 <stab_binsearch+0x54>
f0102957:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010295b:	83 ea 0c             	sub    $0xc,%edx
f010295e:	39 f9                	cmp    %edi,%ecx
f0102960:	75 ee                	jne    f0102950 <stab_binsearch+0x40>
f0102962:	eb 05                	jmp    f0102969 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102964:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102967:	eb 4b                	jmp    f01029b4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102969:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010296c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010296f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102973:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102976:	76 11                	jbe    f0102989 <stab_binsearch+0x79>
			*region_left = m;
f0102978:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010297b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010297d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102980:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102987:	eb 2b                	jmp    f01029b4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102989:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010298c:	73 14                	jae    f01029a2 <stab_binsearch+0x92>
			*region_right = m - 1;
f010298e:	83 e8 01             	sub    $0x1,%eax
f0102991:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102994:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102997:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102999:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01029a0:	eb 12                	jmp    f01029b4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01029a2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029a5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01029a7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01029ab:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01029ad:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01029b4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01029b7:	0f 8e 78 ff ff ff    	jle    f0102935 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01029bd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01029c1:	75 0f                	jne    f01029d2 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01029c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029c6:	8b 00                	mov    (%eax),%eax
f01029c8:	83 e8 01             	sub    $0x1,%eax
f01029cb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01029ce:	89 06                	mov    %eax,(%esi)
f01029d0:	eb 2c                	jmp    f01029fe <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029d5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01029d7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029da:	8b 0e                	mov    (%esi),%ecx
f01029dc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01029df:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01029e2:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029e5:	eb 03                	jmp    f01029ea <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01029e7:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029ea:	39 c8                	cmp    %ecx,%eax
f01029ec:	7e 0b                	jle    f01029f9 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01029ee:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01029f2:	83 ea 0c             	sub    $0xc,%edx
f01029f5:	39 df                	cmp    %ebx,%edi
f01029f7:	75 ee                	jne    f01029e7 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01029f9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029fc:	89 06                	mov    %eax,(%esi)
	}
}
f01029fe:	83 c4 14             	add    $0x14,%esp
f0102a01:	5b                   	pop    %ebx
f0102a02:	5e                   	pop    %esi
f0102a03:	5f                   	pop    %edi
f0102a04:	5d                   	pop    %ebp
f0102a05:	c3                   	ret    

f0102a06 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102a06:	55                   	push   %ebp
f0102a07:	89 e5                	mov    %esp,%ebp
f0102a09:	57                   	push   %edi
f0102a0a:	56                   	push   %esi
f0102a0b:	53                   	push   %ebx
f0102a0c:	83 ec 1c             	sub    $0x1c,%esp
f0102a0f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102a12:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102a15:	c7 06 ac 48 10 f0    	movl   $0xf01048ac,(%esi)
	info->eip_line = 0;
f0102a1b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0102a22:	c7 46 08 ac 48 10 f0 	movl   $0xf01048ac,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102a29:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0102a30:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102a33:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102a3a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0102a40:	76 11                	jbe    f0102a53 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102a42:	b8 2b c3 10 f0       	mov    $0xf010c32b,%eax
f0102a47:	3d ad a5 10 f0       	cmp    $0xf010a5ad,%eax
f0102a4c:	77 19                	ja     f0102a67 <debuginfo_eip+0x61>
f0102a4e:	e9 62 01 00 00       	jmp    f0102bb5 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102a53:	83 ec 04             	sub    $0x4,%esp
f0102a56:	68 b6 48 10 f0       	push   $0xf01048b6
f0102a5b:	6a 7f                	push   $0x7f
f0102a5d:	68 c3 48 10 f0       	push   $0xf01048c3
f0102a62:	e8 24 d6 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102a67:	80 3d 2a c3 10 f0 00 	cmpb   $0x0,0xf010c32a
f0102a6e:	0f 85 48 01 00 00    	jne    f0102bbc <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102a74:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102a7b:	b8 ac a5 10 f0       	mov    $0xf010a5ac,%eax
f0102a80:	2d e0 4a 10 f0       	sub    $0xf0104ae0,%eax
f0102a85:	c1 f8 02             	sar    $0x2,%eax
f0102a88:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102a8e:	83 e8 01             	sub    $0x1,%eax
f0102a91:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102a94:	83 ec 08             	sub    $0x8,%esp
f0102a97:	57                   	push   %edi
f0102a98:	6a 64                	push   $0x64
f0102a9a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102a9d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102aa0:	b8 e0 4a 10 f0       	mov    $0xf0104ae0,%eax
f0102aa5:	e8 66 fe ff ff       	call   f0102910 <stab_binsearch>
	if (lfile == 0)
f0102aaa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102aad:	83 c4 10             	add    $0x10,%esp
f0102ab0:	85 c0                	test   %eax,%eax
f0102ab2:	0f 84 0b 01 00 00    	je     f0102bc3 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102ab8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102abb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102abe:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102ac1:	83 ec 08             	sub    $0x8,%esp
f0102ac4:	57                   	push   %edi
f0102ac5:	6a 24                	push   $0x24
f0102ac7:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102aca:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102acd:	b8 e0 4a 10 f0       	mov    $0xf0104ae0,%eax
f0102ad2:	e8 39 fe ff ff       	call   f0102910 <stab_binsearch>

	if (lfun <= rfun) {
f0102ad7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102ada:	83 c4 10             	add    $0x10,%esp
f0102add:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0102ae0:	7f 31                	jg     f0102b13 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102ae2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102ae5:	c1 e0 02             	shl    $0x2,%eax
f0102ae8:	8d 90 e0 4a 10 f0    	lea    -0xfefb520(%eax),%edx
f0102aee:	8b 88 e0 4a 10 f0    	mov    -0xfefb520(%eax),%ecx
f0102af4:	b8 2b c3 10 f0       	mov    $0xf010c32b,%eax
f0102af9:	2d ad a5 10 f0       	sub    $0xf010a5ad,%eax
f0102afe:	39 c1                	cmp    %eax,%ecx
f0102b00:	73 09                	jae    f0102b0b <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102b02:	81 c1 ad a5 10 f0    	add    $0xf010a5ad,%ecx
f0102b08:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102b0b:	8b 42 08             	mov    0x8(%edx),%eax
f0102b0e:	89 46 10             	mov    %eax,0x10(%esi)
f0102b11:	eb 06                	jmp    f0102b19 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102b13:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102b16:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102b19:	83 ec 08             	sub    $0x8,%esp
f0102b1c:	6a 3a                	push   $0x3a
f0102b1e:	ff 76 08             	pushl  0x8(%esi)
f0102b21:	e8 a3 08 00 00       	call   f01033c9 <strfind>
f0102b26:	2b 46 08             	sub    0x8(%esi),%eax
f0102b29:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b2f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102b32:	8d 04 85 e0 4a 10 f0 	lea    -0xfefb520(,%eax,4),%eax
f0102b39:	83 c4 10             	add    $0x10,%esp
f0102b3c:	eb 06                	jmp    f0102b44 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102b3e:	83 eb 01             	sub    $0x1,%ebx
f0102b41:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b44:	39 fb                	cmp    %edi,%ebx
f0102b46:	7c 34                	jl     f0102b7c <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0102b48:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0102b4c:	80 fa 84             	cmp    $0x84,%dl
f0102b4f:	74 0b                	je     f0102b5c <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102b51:	80 fa 64             	cmp    $0x64,%dl
f0102b54:	75 e8                	jne    f0102b3e <debuginfo_eip+0x138>
f0102b56:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102b5a:	74 e2                	je     f0102b3e <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102b5c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102b5f:	8b 14 85 e0 4a 10 f0 	mov    -0xfefb520(,%eax,4),%edx
f0102b66:	b8 2b c3 10 f0       	mov    $0xf010c32b,%eax
f0102b6b:	2d ad a5 10 f0       	sub    $0xf010a5ad,%eax
f0102b70:	39 c2                	cmp    %eax,%edx
f0102b72:	73 08                	jae    f0102b7c <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102b74:	81 c2 ad a5 10 f0    	add    $0xf010a5ad,%edx
f0102b7a:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b7c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102b7f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b82:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b87:	39 cb                	cmp    %ecx,%ebx
f0102b89:	7d 44                	jge    f0102bcf <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102b8b:	8d 53 01             	lea    0x1(%ebx),%edx
f0102b8e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102b91:	8d 04 85 e0 4a 10 f0 	lea    -0xfefb520(,%eax,4),%eax
f0102b98:	eb 07                	jmp    f0102ba1 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102b9a:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102b9e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ba1:	39 ca                	cmp    %ecx,%edx
f0102ba3:	74 25                	je     f0102bca <debuginfo_eip+0x1c4>
f0102ba5:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ba8:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102bac:	74 ec                	je     f0102b9a <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bae:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb3:	eb 1a                	jmp    f0102bcf <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102bb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bba:	eb 13                	jmp    f0102bcf <debuginfo_eip+0x1c9>
f0102bbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bc1:	eb 0c                	jmp    f0102bcf <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102bc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bc8:	eb 05                	jmp    f0102bcf <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102bcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bd2:	5b                   	pop    %ebx
f0102bd3:	5e                   	pop    %esi
f0102bd4:	5f                   	pop    %edi
f0102bd5:	5d                   	pop    %ebp
f0102bd6:	c3                   	ret    

f0102bd7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102bd7:	55                   	push   %ebp
f0102bd8:	89 e5                	mov    %esp,%ebp
f0102bda:	57                   	push   %edi
f0102bdb:	56                   	push   %esi
f0102bdc:	53                   	push   %ebx
f0102bdd:	83 ec 1c             	sub    $0x1c,%esp
f0102be0:	89 c7                	mov    %eax,%edi
f0102be2:	89 d6                	mov    %edx,%esi
f0102be4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102be7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102bea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bed:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102bf0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102bf3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bf8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102bfb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102bfe:	39 d3                	cmp    %edx,%ebx
f0102c00:	72 05                	jb     f0102c07 <printnum+0x30>
f0102c02:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102c05:	77 45                	ja     f0102c4c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102c07:	83 ec 0c             	sub    $0xc,%esp
f0102c0a:	ff 75 18             	pushl  0x18(%ebp)
f0102c0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c10:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102c13:	53                   	push   %ebx
f0102c14:	ff 75 10             	pushl  0x10(%ebp)
f0102c17:	83 ec 08             	sub    $0x8,%esp
f0102c1a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c1d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c20:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c23:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c26:	e8 c5 09 00 00       	call   f01035f0 <__udivdi3>
f0102c2b:	83 c4 18             	add    $0x18,%esp
f0102c2e:	52                   	push   %edx
f0102c2f:	50                   	push   %eax
f0102c30:	89 f2                	mov    %esi,%edx
f0102c32:	89 f8                	mov    %edi,%eax
f0102c34:	e8 9e ff ff ff       	call   f0102bd7 <printnum>
f0102c39:	83 c4 20             	add    $0x20,%esp
f0102c3c:	eb 18                	jmp    f0102c56 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102c3e:	83 ec 08             	sub    $0x8,%esp
f0102c41:	56                   	push   %esi
f0102c42:	ff 75 18             	pushl  0x18(%ebp)
f0102c45:	ff d7                	call   *%edi
f0102c47:	83 c4 10             	add    $0x10,%esp
f0102c4a:	eb 03                	jmp    f0102c4f <printnum+0x78>
f0102c4c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102c4f:	83 eb 01             	sub    $0x1,%ebx
f0102c52:	85 db                	test   %ebx,%ebx
f0102c54:	7f e8                	jg     f0102c3e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102c56:	83 ec 08             	sub    $0x8,%esp
f0102c59:	56                   	push   %esi
f0102c5a:	83 ec 04             	sub    $0x4,%esp
f0102c5d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c60:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c63:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c66:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c69:	e8 b2 0a 00 00       	call   f0103720 <__umoddi3>
f0102c6e:	83 c4 14             	add    $0x14,%esp
f0102c71:	0f be 80 d1 48 10 f0 	movsbl -0xfefb72f(%eax),%eax
f0102c78:	50                   	push   %eax
f0102c79:	ff d7                	call   *%edi
}
f0102c7b:	83 c4 10             	add    $0x10,%esp
f0102c7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c81:	5b                   	pop    %ebx
f0102c82:	5e                   	pop    %esi
f0102c83:	5f                   	pop    %edi
f0102c84:	5d                   	pop    %ebp
f0102c85:	c3                   	ret    

f0102c86 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c86:	55                   	push   %ebp
f0102c87:	89 e5                	mov    %esp,%ebp
f0102c89:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c8c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102c90:	8b 10                	mov    (%eax),%edx
f0102c92:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c95:	73 0a                	jae    f0102ca1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102c97:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c9a:	89 08                	mov    %ecx,(%eax)
f0102c9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c9f:	88 02                	mov    %al,(%edx)
}
f0102ca1:	5d                   	pop    %ebp
f0102ca2:	c3                   	ret    

f0102ca3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102ca3:	55                   	push   %ebp
f0102ca4:	89 e5                	mov    %esp,%ebp
f0102ca6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102ca9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102cac:	50                   	push   %eax
f0102cad:	ff 75 10             	pushl  0x10(%ebp)
f0102cb0:	ff 75 0c             	pushl  0xc(%ebp)
f0102cb3:	ff 75 08             	pushl  0x8(%ebp)
f0102cb6:	e8 05 00 00 00       	call   f0102cc0 <vprintfmt>
	va_end(ap);
}
f0102cbb:	83 c4 10             	add    $0x10,%esp
f0102cbe:	c9                   	leave  
f0102cbf:	c3                   	ret    

f0102cc0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102cc0:	55                   	push   %ebp
f0102cc1:	89 e5                	mov    %esp,%ebp
f0102cc3:	57                   	push   %edi
f0102cc4:	56                   	push   %esi
f0102cc5:	53                   	push   %ebx
f0102cc6:	83 ec 2c             	sub    $0x2c,%esp
f0102cc9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ccc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ccf:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102cd2:	eb 12                	jmp    f0102ce6 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102cd4:	85 c0                	test   %eax,%eax
f0102cd6:	0f 84 42 04 00 00    	je     f010311e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102cdc:	83 ec 08             	sub    $0x8,%esp
f0102cdf:	53                   	push   %ebx
f0102ce0:	50                   	push   %eax
f0102ce1:	ff d6                	call   *%esi
f0102ce3:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102ce6:	83 c7 01             	add    $0x1,%edi
f0102ce9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ced:	83 f8 25             	cmp    $0x25,%eax
f0102cf0:	75 e2                	jne    f0102cd4 <vprintfmt+0x14>
f0102cf2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102cf6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102cfd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d04:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102d0b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d10:	eb 07                	jmp    f0102d19 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d12:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102d15:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d19:	8d 47 01             	lea    0x1(%edi),%eax
f0102d1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102d1f:	0f b6 07             	movzbl (%edi),%eax
f0102d22:	0f b6 d0             	movzbl %al,%edx
f0102d25:	83 e8 23             	sub    $0x23,%eax
f0102d28:	3c 55                	cmp    $0x55,%al
f0102d2a:	0f 87 d3 03 00 00    	ja     f0103103 <vprintfmt+0x443>
f0102d30:	0f b6 c0             	movzbl %al,%eax
f0102d33:	ff 24 85 5c 49 10 f0 	jmp    *-0xfefb6a4(,%eax,4)
f0102d3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102d3d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102d41:	eb d6                	jmp    f0102d19 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d46:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d4b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102d4e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102d51:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102d55:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102d58:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102d5b:	83 f9 09             	cmp    $0x9,%ecx
f0102d5e:	77 3f                	ja     f0102d9f <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102d60:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102d63:	eb e9                	jmp    f0102d4e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102d65:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d68:	8b 00                	mov    (%eax),%eax
f0102d6a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d70:	8d 40 04             	lea    0x4(%eax),%eax
f0102d73:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102d79:	eb 2a                	jmp    f0102da5 <vprintfmt+0xe5>
f0102d7b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d7e:	85 c0                	test   %eax,%eax
f0102d80:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d85:	0f 49 d0             	cmovns %eax,%edx
f0102d88:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d8e:	eb 89                	jmp    f0102d19 <vprintfmt+0x59>
f0102d90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d93:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d9a:	e9 7a ff ff ff       	jmp    f0102d19 <vprintfmt+0x59>
f0102d9f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102da2:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102da5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102da9:	0f 89 6a ff ff ff    	jns    f0102d19 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102daf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102db2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102db5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102dbc:	e9 58 ff ff ff       	jmp    f0102d19 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102dc1:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102dc7:	e9 4d ff ff ff       	jmp    f0102d19 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102dcc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dcf:	8d 78 04             	lea    0x4(%eax),%edi
f0102dd2:	83 ec 08             	sub    $0x8,%esp
f0102dd5:	53                   	push   %ebx
f0102dd6:	ff 30                	pushl  (%eax)
f0102dd8:	ff d6                	call   *%esi
			break;
f0102dda:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102ddd:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102de0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102de3:	e9 fe fe ff ff       	jmp    f0102ce6 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102de8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102deb:	8d 78 04             	lea    0x4(%eax),%edi
f0102dee:	8b 00                	mov    (%eax),%eax
f0102df0:	99                   	cltd   
f0102df1:	31 d0                	xor    %edx,%eax
f0102df3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102df5:	83 f8 06             	cmp    $0x6,%eax
f0102df8:	7f 0b                	jg     f0102e05 <vprintfmt+0x145>
f0102dfa:	8b 14 85 b4 4a 10 f0 	mov    -0xfefb54c(,%eax,4),%edx
f0102e01:	85 d2                	test   %edx,%edx
f0102e03:	75 1b                	jne    f0102e20 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102e05:	50                   	push   %eax
f0102e06:	68 e9 48 10 f0       	push   $0xf01048e9
f0102e0b:	53                   	push   %ebx
f0102e0c:	56                   	push   %esi
f0102e0d:	e8 91 fe ff ff       	call   f0102ca3 <printfmt>
f0102e12:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e15:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102e1b:	e9 c6 fe ff ff       	jmp    f0102ce6 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102e20:	52                   	push   %edx
f0102e21:	68 e5 3d 10 f0       	push   $0xf0103de5
f0102e26:	53                   	push   %ebx
f0102e27:	56                   	push   %esi
f0102e28:	e8 76 fe ff ff       	call   f0102ca3 <printfmt>
f0102e2d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e30:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e36:	e9 ab fe ff ff       	jmp    f0102ce6 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e3e:	83 c0 04             	add    $0x4,%eax
f0102e41:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102e44:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e47:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102e49:	85 ff                	test   %edi,%edi
f0102e4b:	b8 e2 48 10 f0       	mov    $0xf01048e2,%eax
f0102e50:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102e53:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102e57:	0f 8e 94 00 00 00    	jle    f0102ef1 <vprintfmt+0x231>
f0102e5d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102e61:	0f 84 98 00 00 00    	je     f0102eff <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e67:	83 ec 08             	sub    $0x8,%esp
f0102e6a:	ff 75 d0             	pushl  -0x30(%ebp)
f0102e6d:	57                   	push   %edi
f0102e6e:	e8 0c 04 00 00       	call   f010327f <strnlen>
f0102e73:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102e76:	29 c1                	sub    %eax,%ecx
f0102e78:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102e7b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102e7e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e82:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e85:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e88:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e8a:	eb 0f                	jmp    f0102e9b <vprintfmt+0x1db>
					putch(padc, putdat);
f0102e8c:	83 ec 08             	sub    $0x8,%esp
f0102e8f:	53                   	push   %ebx
f0102e90:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e93:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e95:	83 ef 01             	sub    $0x1,%edi
f0102e98:	83 c4 10             	add    $0x10,%esp
f0102e9b:	85 ff                	test   %edi,%edi
f0102e9d:	7f ed                	jg     f0102e8c <vprintfmt+0x1cc>
f0102e9f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ea2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102ea5:	85 c9                	test   %ecx,%ecx
f0102ea7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eac:	0f 49 c1             	cmovns %ecx,%eax
f0102eaf:	29 c1                	sub    %eax,%ecx
f0102eb1:	89 75 08             	mov    %esi,0x8(%ebp)
f0102eb4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102eb7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102eba:	89 cb                	mov    %ecx,%ebx
f0102ebc:	eb 4d                	jmp    f0102f0b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102ebe:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102ec2:	74 1b                	je     f0102edf <vprintfmt+0x21f>
f0102ec4:	0f be c0             	movsbl %al,%eax
f0102ec7:	83 e8 20             	sub    $0x20,%eax
f0102eca:	83 f8 5e             	cmp    $0x5e,%eax
f0102ecd:	76 10                	jbe    f0102edf <vprintfmt+0x21f>
					putch('?', putdat);
f0102ecf:	83 ec 08             	sub    $0x8,%esp
f0102ed2:	ff 75 0c             	pushl  0xc(%ebp)
f0102ed5:	6a 3f                	push   $0x3f
f0102ed7:	ff 55 08             	call   *0x8(%ebp)
f0102eda:	83 c4 10             	add    $0x10,%esp
f0102edd:	eb 0d                	jmp    f0102eec <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102edf:	83 ec 08             	sub    $0x8,%esp
f0102ee2:	ff 75 0c             	pushl  0xc(%ebp)
f0102ee5:	52                   	push   %edx
f0102ee6:	ff 55 08             	call   *0x8(%ebp)
f0102ee9:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102eec:	83 eb 01             	sub    $0x1,%ebx
f0102eef:	eb 1a                	jmp    f0102f0b <vprintfmt+0x24b>
f0102ef1:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ef4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ef7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102efa:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102efd:	eb 0c                	jmp    f0102f0b <vprintfmt+0x24b>
f0102eff:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f02:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f05:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f08:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f0b:	83 c7 01             	add    $0x1,%edi
f0102f0e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102f12:	0f be d0             	movsbl %al,%edx
f0102f15:	85 d2                	test   %edx,%edx
f0102f17:	74 23                	je     f0102f3c <vprintfmt+0x27c>
f0102f19:	85 f6                	test   %esi,%esi
f0102f1b:	78 a1                	js     f0102ebe <vprintfmt+0x1fe>
f0102f1d:	83 ee 01             	sub    $0x1,%esi
f0102f20:	79 9c                	jns    f0102ebe <vprintfmt+0x1fe>
f0102f22:	89 df                	mov    %ebx,%edi
f0102f24:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f2a:	eb 18                	jmp    f0102f44 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102f2c:	83 ec 08             	sub    $0x8,%esp
f0102f2f:	53                   	push   %ebx
f0102f30:	6a 20                	push   $0x20
f0102f32:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102f34:	83 ef 01             	sub    $0x1,%edi
f0102f37:	83 c4 10             	add    $0x10,%esp
f0102f3a:	eb 08                	jmp    f0102f44 <vprintfmt+0x284>
f0102f3c:	89 df                	mov    %ebx,%edi
f0102f3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f41:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f44:	85 ff                	test   %edi,%edi
f0102f46:	7f e4                	jg     f0102f2c <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102f48:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102f4b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f4e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f51:	e9 90 fd ff ff       	jmp    f0102ce6 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f56:	83 f9 01             	cmp    $0x1,%ecx
f0102f59:	7e 19                	jle    f0102f74 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102f5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f5e:	8b 50 04             	mov    0x4(%eax),%edx
f0102f61:	8b 00                	mov    (%eax),%eax
f0102f63:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f66:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102f69:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f6c:	8d 40 08             	lea    0x8(%eax),%eax
f0102f6f:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f72:	eb 38                	jmp    f0102fac <vprintfmt+0x2ec>
	else if (lflag)
f0102f74:	85 c9                	test   %ecx,%ecx
f0102f76:	74 1b                	je     f0102f93 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102f78:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7b:	8b 00                	mov    (%eax),%eax
f0102f7d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f80:	89 c1                	mov    %eax,%ecx
f0102f82:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f85:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f88:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f8b:	8d 40 04             	lea    0x4(%eax),%eax
f0102f8e:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f91:	eb 19                	jmp    f0102fac <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102f93:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f96:	8b 00                	mov    (%eax),%eax
f0102f98:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f9b:	89 c1                	mov    %eax,%ecx
f0102f9d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102fa0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102fa3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fa6:	8d 40 04             	lea    0x4(%eax),%eax
f0102fa9:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102fac:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102faf:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102fb2:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102fb7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102fbb:	0f 89 0e 01 00 00    	jns    f01030cf <vprintfmt+0x40f>
				putch('-', putdat);
f0102fc1:	83 ec 08             	sub    $0x8,%esp
f0102fc4:	53                   	push   %ebx
f0102fc5:	6a 2d                	push   $0x2d
f0102fc7:	ff d6                	call   *%esi
				num = -(long long) num;
f0102fc9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fcc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102fcf:	f7 da                	neg    %edx
f0102fd1:	83 d1 00             	adc    $0x0,%ecx
f0102fd4:	f7 d9                	neg    %ecx
f0102fd6:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102fd9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fde:	e9 ec 00 00 00       	jmp    f01030cf <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102fe3:	83 f9 01             	cmp    $0x1,%ecx
f0102fe6:	7e 18                	jle    f0103000 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102fe8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102feb:	8b 10                	mov    (%eax),%edx
f0102fed:	8b 48 04             	mov    0x4(%eax),%ecx
f0102ff0:	8d 40 08             	lea    0x8(%eax),%eax
f0102ff3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ff6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ffb:	e9 cf 00 00 00       	jmp    f01030cf <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103000:	85 c9                	test   %ecx,%ecx
f0103002:	74 1a                	je     f010301e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103004:	8b 45 14             	mov    0x14(%ebp),%eax
f0103007:	8b 10                	mov    (%eax),%edx
f0103009:	b9 00 00 00 00       	mov    $0x0,%ecx
f010300e:	8d 40 04             	lea    0x4(%eax),%eax
f0103011:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103014:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103019:	e9 b1 00 00 00       	jmp    f01030cf <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010301e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103021:	8b 10                	mov    (%eax),%edx
f0103023:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103028:	8d 40 04             	lea    0x4(%eax),%eax
f010302b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010302e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103033:	e9 97 00 00 00       	jmp    f01030cf <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103038:	83 ec 08             	sub    $0x8,%esp
f010303b:	53                   	push   %ebx
f010303c:	6a 58                	push   $0x58
f010303e:	ff d6                	call   *%esi
			putch('X', putdat);
f0103040:	83 c4 08             	add    $0x8,%esp
f0103043:	53                   	push   %ebx
f0103044:	6a 58                	push   $0x58
f0103046:	ff d6                	call   *%esi
			putch('X', putdat);
f0103048:	83 c4 08             	add    $0x8,%esp
f010304b:	53                   	push   %ebx
f010304c:	6a 58                	push   $0x58
f010304e:	ff d6                	call   *%esi
			break;
f0103050:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103053:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103056:	e9 8b fc ff ff       	jmp    f0102ce6 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010305b:	83 ec 08             	sub    $0x8,%esp
f010305e:	53                   	push   %ebx
f010305f:	6a 30                	push   $0x30
f0103061:	ff d6                	call   *%esi
			putch('x', putdat);
f0103063:	83 c4 08             	add    $0x8,%esp
f0103066:	53                   	push   %ebx
f0103067:	6a 78                	push   $0x78
f0103069:	ff d6                	call   *%esi
			num = (unsigned long long)
f010306b:	8b 45 14             	mov    0x14(%ebp),%eax
f010306e:	8b 10                	mov    (%eax),%edx
f0103070:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103075:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103078:	8d 40 04             	lea    0x4(%eax),%eax
f010307b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010307e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103083:	eb 4a                	jmp    f01030cf <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103085:	83 f9 01             	cmp    $0x1,%ecx
f0103088:	7e 15                	jle    f010309f <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f010308a:	8b 45 14             	mov    0x14(%ebp),%eax
f010308d:	8b 10                	mov    (%eax),%edx
f010308f:	8b 48 04             	mov    0x4(%eax),%ecx
f0103092:	8d 40 08             	lea    0x8(%eax),%eax
f0103095:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103098:	b8 10 00 00 00       	mov    $0x10,%eax
f010309d:	eb 30                	jmp    f01030cf <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010309f:	85 c9                	test   %ecx,%ecx
f01030a1:	74 17                	je     f01030ba <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01030a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01030a6:	8b 10                	mov    (%eax),%edx
f01030a8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01030ad:	8d 40 04             	lea    0x4(%eax),%eax
f01030b0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01030b3:	b8 10 00 00 00       	mov    $0x10,%eax
f01030b8:	eb 15                	jmp    f01030cf <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01030ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01030bd:	8b 10                	mov    (%eax),%edx
f01030bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01030c4:	8d 40 04             	lea    0x4(%eax),%eax
f01030c7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01030ca:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01030cf:	83 ec 0c             	sub    $0xc,%esp
f01030d2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01030d6:	57                   	push   %edi
f01030d7:	ff 75 e0             	pushl  -0x20(%ebp)
f01030da:	50                   	push   %eax
f01030db:	51                   	push   %ecx
f01030dc:	52                   	push   %edx
f01030dd:	89 da                	mov    %ebx,%edx
f01030df:	89 f0                	mov    %esi,%eax
f01030e1:	e8 f1 fa ff ff       	call   f0102bd7 <printnum>
			break;
f01030e6:	83 c4 20             	add    $0x20,%esp
f01030e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030ec:	e9 f5 fb ff ff       	jmp    f0102ce6 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01030f1:	83 ec 08             	sub    $0x8,%esp
f01030f4:	53                   	push   %ebx
f01030f5:	52                   	push   %edx
f01030f6:	ff d6                	call   *%esi
			break;
f01030f8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01030fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01030fe:	e9 e3 fb ff ff       	jmp    f0102ce6 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103103:	83 ec 08             	sub    $0x8,%esp
f0103106:	53                   	push   %ebx
f0103107:	6a 25                	push   $0x25
f0103109:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010310b:	83 c4 10             	add    $0x10,%esp
f010310e:	eb 03                	jmp    f0103113 <vprintfmt+0x453>
f0103110:	83 ef 01             	sub    $0x1,%edi
f0103113:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103117:	75 f7                	jne    f0103110 <vprintfmt+0x450>
f0103119:	e9 c8 fb ff ff       	jmp    f0102ce6 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010311e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103121:	5b                   	pop    %ebx
f0103122:	5e                   	pop    %esi
f0103123:	5f                   	pop    %edi
f0103124:	5d                   	pop    %ebp
f0103125:	c3                   	ret    

f0103126 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103126:	55                   	push   %ebp
f0103127:	89 e5                	mov    %esp,%ebp
f0103129:	83 ec 18             	sub    $0x18,%esp
f010312c:	8b 45 08             	mov    0x8(%ebp),%eax
f010312f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103132:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103135:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103139:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010313c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103143:	85 c0                	test   %eax,%eax
f0103145:	74 26                	je     f010316d <vsnprintf+0x47>
f0103147:	85 d2                	test   %edx,%edx
f0103149:	7e 22                	jle    f010316d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010314b:	ff 75 14             	pushl  0x14(%ebp)
f010314e:	ff 75 10             	pushl  0x10(%ebp)
f0103151:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103154:	50                   	push   %eax
f0103155:	68 86 2c 10 f0       	push   $0xf0102c86
f010315a:	e8 61 fb ff ff       	call   f0102cc0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010315f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103162:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103165:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103168:	83 c4 10             	add    $0x10,%esp
f010316b:	eb 05                	jmp    f0103172 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010316d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103172:	c9                   	leave  
f0103173:	c3                   	ret    

f0103174 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103174:	55                   	push   %ebp
f0103175:	89 e5                	mov    %esp,%ebp
f0103177:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010317a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010317d:	50                   	push   %eax
f010317e:	ff 75 10             	pushl  0x10(%ebp)
f0103181:	ff 75 0c             	pushl  0xc(%ebp)
f0103184:	ff 75 08             	pushl  0x8(%ebp)
f0103187:	e8 9a ff ff ff       	call   f0103126 <vsnprintf>
	va_end(ap);

	return rc;
}
f010318c:	c9                   	leave  
f010318d:	c3                   	ret    

f010318e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010318e:	55                   	push   %ebp
f010318f:	89 e5                	mov    %esp,%ebp
f0103191:	57                   	push   %edi
f0103192:	56                   	push   %esi
f0103193:	53                   	push   %ebx
f0103194:	83 ec 0c             	sub    $0xc,%esp
f0103197:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010319a:	85 c0                	test   %eax,%eax
f010319c:	74 11                	je     f01031af <readline+0x21>
		cprintf("%s", prompt);
f010319e:	83 ec 08             	sub    $0x8,%esp
f01031a1:	50                   	push   %eax
f01031a2:	68 e5 3d 10 f0       	push   $0xf0103de5
f01031a7:	e8 50 f7 ff ff       	call   f01028fc <cprintf>
f01031ac:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01031af:	83 ec 0c             	sub    $0xc,%esp
f01031b2:	6a 00                	push   $0x0
f01031b4:	e8 68 d4 ff ff       	call   f0100621 <iscons>
f01031b9:	89 c7                	mov    %eax,%edi
f01031bb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01031be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01031c3:	e8 48 d4 ff ff       	call   f0100610 <getchar>
f01031c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01031ca:	85 c0                	test   %eax,%eax
f01031cc:	79 18                	jns    f01031e6 <readline+0x58>
			cprintf("read error: %e\n", c);
f01031ce:	83 ec 08             	sub    $0x8,%esp
f01031d1:	50                   	push   %eax
f01031d2:	68 d0 4a 10 f0       	push   $0xf0104ad0
f01031d7:	e8 20 f7 ff ff       	call   f01028fc <cprintf>
			return NULL;
f01031dc:	83 c4 10             	add    $0x10,%esp
f01031df:	b8 00 00 00 00       	mov    $0x0,%eax
f01031e4:	eb 79                	jmp    f010325f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01031e6:	83 f8 08             	cmp    $0x8,%eax
f01031e9:	0f 94 c2             	sete   %dl
f01031ec:	83 f8 7f             	cmp    $0x7f,%eax
f01031ef:	0f 94 c0             	sete   %al
f01031f2:	08 c2                	or     %al,%dl
f01031f4:	74 1a                	je     f0103210 <readline+0x82>
f01031f6:	85 f6                	test   %esi,%esi
f01031f8:	7e 16                	jle    f0103210 <readline+0x82>
			if (echoing)
f01031fa:	85 ff                	test   %edi,%edi
f01031fc:	74 0d                	je     f010320b <readline+0x7d>
				cputchar('\b');
f01031fe:	83 ec 0c             	sub    $0xc,%esp
f0103201:	6a 08                	push   $0x8
f0103203:	e8 f8 d3 ff ff       	call   f0100600 <cputchar>
f0103208:	83 c4 10             	add    $0x10,%esp
			i--;
f010320b:	83 ee 01             	sub    $0x1,%esi
f010320e:	eb b3                	jmp    f01031c3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103210:	83 fb 1f             	cmp    $0x1f,%ebx
f0103213:	7e 23                	jle    f0103238 <readline+0xaa>
f0103215:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010321b:	7f 1b                	jg     f0103238 <readline+0xaa>
			if (echoing)
f010321d:	85 ff                	test   %edi,%edi
f010321f:	74 0c                	je     f010322d <readline+0x9f>
				cputchar(c);
f0103221:	83 ec 0c             	sub    $0xc,%esp
f0103224:	53                   	push   %ebx
f0103225:	e8 d6 d3 ff ff       	call   f0100600 <cputchar>
f010322a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010322d:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103233:	8d 76 01             	lea    0x1(%esi),%esi
f0103236:	eb 8b                	jmp    f01031c3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103238:	83 fb 0a             	cmp    $0xa,%ebx
f010323b:	74 05                	je     f0103242 <readline+0xb4>
f010323d:	83 fb 0d             	cmp    $0xd,%ebx
f0103240:	75 81                	jne    f01031c3 <readline+0x35>
			if (echoing)
f0103242:	85 ff                	test   %edi,%edi
f0103244:	74 0d                	je     f0103253 <readline+0xc5>
				cputchar('\n');
f0103246:	83 ec 0c             	sub    $0xc,%esp
f0103249:	6a 0a                	push   $0xa
f010324b:	e8 b0 d3 ff ff       	call   f0100600 <cputchar>
f0103250:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103253:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010325a:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f010325f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103262:	5b                   	pop    %ebx
f0103263:	5e                   	pop    %esi
f0103264:	5f                   	pop    %edi
f0103265:	5d                   	pop    %ebp
f0103266:	c3                   	ret    

f0103267 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103267:	55                   	push   %ebp
f0103268:	89 e5                	mov    %esp,%ebp
f010326a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010326d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103272:	eb 03                	jmp    f0103277 <strlen+0x10>
		n++;
f0103274:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103277:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010327b:	75 f7                	jne    f0103274 <strlen+0xd>
		n++;
	return n;
}
f010327d:	5d                   	pop    %ebp
f010327e:	c3                   	ret    

f010327f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010327f:	55                   	push   %ebp
f0103280:	89 e5                	mov    %esp,%ebp
f0103282:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103285:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103288:	ba 00 00 00 00       	mov    $0x0,%edx
f010328d:	eb 03                	jmp    f0103292 <strnlen+0x13>
		n++;
f010328f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103292:	39 c2                	cmp    %eax,%edx
f0103294:	74 08                	je     f010329e <strnlen+0x1f>
f0103296:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010329a:	75 f3                	jne    f010328f <strnlen+0x10>
f010329c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010329e:	5d                   	pop    %ebp
f010329f:	c3                   	ret    

f01032a0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01032a0:	55                   	push   %ebp
f01032a1:	89 e5                	mov    %esp,%ebp
f01032a3:	53                   	push   %ebx
f01032a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01032aa:	89 c2                	mov    %eax,%edx
f01032ac:	83 c2 01             	add    $0x1,%edx
f01032af:	83 c1 01             	add    $0x1,%ecx
f01032b2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01032b6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01032b9:	84 db                	test   %bl,%bl
f01032bb:	75 ef                	jne    f01032ac <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01032bd:	5b                   	pop    %ebx
f01032be:	5d                   	pop    %ebp
f01032bf:	c3                   	ret    

f01032c0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	53                   	push   %ebx
f01032c4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01032c7:	53                   	push   %ebx
f01032c8:	e8 9a ff ff ff       	call   f0103267 <strlen>
f01032cd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01032d0:	ff 75 0c             	pushl  0xc(%ebp)
f01032d3:	01 d8                	add    %ebx,%eax
f01032d5:	50                   	push   %eax
f01032d6:	e8 c5 ff ff ff       	call   f01032a0 <strcpy>
	return dst;
}
f01032db:	89 d8                	mov    %ebx,%eax
f01032dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032e0:	c9                   	leave  
f01032e1:	c3                   	ret    

f01032e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01032e2:	55                   	push   %ebp
f01032e3:	89 e5                	mov    %esp,%ebp
f01032e5:	56                   	push   %esi
f01032e6:	53                   	push   %ebx
f01032e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01032ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032ed:	89 f3                	mov    %esi,%ebx
f01032ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01032f2:	89 f2                	mov    %esi,%edx
f01032f4:	eb 0f                	jmp    f0103305 <strncpy+0x23>
		*dst++ = *src;
f01032f6:	83 c2 01             	add    $0x1,%edx
f01032f9:	0f b6 01             	movzbl (%ecx),%eax
f01032fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01032ff:	80 39 01             	cmpb   $0x1,(%ecx)
f0103302:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103305:	39 da                	cmp    %ebx,%edx
f0103307:	75 ed                	jne    f01032f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103309:	89 f0                	mov    %esi,%eax
f010330b:	5b                   	pop    %ebx
f010330c:	5e                   	pop    %esi
f010330d:	5d                   	pop    %ebp
f010330e:	c3                   	ret    

f010330f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010330f:	55                   	push   %ebp
f0103310:	89 e5                	mov    %esp,%ebp
f0103312:	56                   	push   %esi
f0103313:	53                   	push   %ebx
f0103314:	8b 75 08             	mov    0x8(%ebp),%esi
f0103317:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010331a:	8b 55 10             	mov    0x10(%ebp),%edx
f010331d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010331f:	85 d2                	test   %edx,%edx
f0103321:	74 21                	je     f0103344 <strlcpy+0x35>
f0103323:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103327:	89 f2                	mov    %esi,%edx
f0103329:	eb 09                	jmp    f0103334 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010332b:	83 c2 01             	add    $0x1,%edx
f010332e:	83 c1 01             	add    $0x1,%ecx
f0103331:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103334:	39 c2                	cmp    %eax,%edx
f0103336:	74 09                	je     f0103341 <strlcpy+0x32>
f0103338:	0f b6 19             	movzbl (%ecx),%ebx
f010333b:	84 db                	test   %bl,%bl
f010333d:	75 ec                	jne    f010332b <strlcpy+0x1c>
f010333f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103341:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103344:	29 f0                	sub    %esi,%eax
}
f0103346:	5b                   	pop    %ebx
f0103347:	5e                   	pop    %esi
f0103348:	5d                   	pop    %ebp
f0103349:	c3                   	ret    

f010334a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010334a:	55                   	push   %ebp
f010334b:	89 e5                	mov    %esp,%ebp
f010334d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103350:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103353:	eb 06                	jmp    f010335b <strcmp+0x11>
		p++, q++;
f0103355:	83 c1 01             	add    $0x1,%ecx
f0103358:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010335b:	0f b6 01             	movzbl (%ecx),%eax
f010335e:	84 c0                	test   %al,%al
f0103360:	74 04                	je     f0103366 <strcmp+0x1c>
f0103362:	3a 02                	cmp    (%edx),%al
f0103364:	74 ef                	je     f0103355 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103366:	0f b6 c0             	movzbl %al,%eax
f0103369:	0f b6 12             	movzbl (%edx),%edx
f010336c:	29 d0                	sub    %edx,%eax
}
f010336e:	5d                   	pop    %ebp
f010336f:	c3                   	ret    

f0103370 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103370:	55                   	push   %ebp
f0103371:	89 e5                	mov    %esp,%ebp
f0103373:	53                   	push   %ebx
f0103374:	8b 45 08             	mov    0x8(%ebp),%eax
f0103377:	8b 55 0c             	mov    0xc(%ebp),%edx
f010337a:	89 c3                	mov    %eax,%ebx
f010337c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010337f:	eb 06                	jmp    f0103387 <strncmp+0x17>
		n--, p++, q++;
f0103381:	83 c0 01             	add    $0x1,%eax
f0103384:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103387:	39 d8                	cmp    %ebx,%eax
f0103389:	74 15                	je     f01033a0 <strncmp+0x30>
f010338b:	0f b6 08             	movzbl (%eax),%ecx
f010338e:	84 c9                	test   %cl,%cl
f0103390:	74 04                	je     f0103396 <strncmp+0x26>
f0103392:	3a 0a                	cmp    (%edx),%cl
f0103394:	74 eb                	je     f0103381 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103396:	0f b6 00             	movzbl (%eax),%eax
f0103399:	0f b6 12             	movzbl (%edx),%edx
f010339c:	29 d0                	sub    %edx,%eax
f010339e:	eb 05                	jmp    f01033a5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01033a0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01033a5:	5b                   	pop    %ebx
f01033a6:	5d                   	pop    %ebp
f01033a7:	c3                   	ret    

f01033a8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01033a8:	55                   	push   %ebp
f01033a9:	89 e5                	mov    %esp,%ebp
f01033ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01033ae:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01033b2:	eb 07                	jmp    f01033bb <strchr+0x13>
		if (*s == c)
f01033b4:	38 ca                	cmp    %cl,%dl
f01033b6:	74 0f                	je     f01033c7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01033b8:	83 c0 01             	add    $0x1,%eax
f01033bb:	0f b6 10             	movzbl (%eax),%edx
f01033be:	84 d2                	test   %dl,%dl
f01033c0:	75 f2                	jne    f01033b4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01033c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033c7:	5d                   	pop    %ebp
f01033c8:	c3                   	ret    

f01033c9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01033c9:	55                   	push   %ebp
f01033ca:	89 e5                	mov    %esp,%ebp
f01033cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01033cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01033d3:	eb 03                	jmp    f01033d8 <strfind+0xf>
f01033d5:	83 c0 01             	add    $0x1,%eax
f01033d8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01033db:	38 ca                	cmp    %cl,%dl
f01033dd:	74 04                	je     f01033e3 <strfind+0x1a>
f01033df:	84 d2                	test   %dl,%dl
f01033e1:	75 f2                	jne    f01033d5 <strfind+0xc>
			break;
	return (char *) s;
}
f01033e3:	5d                   	pop    %ebp
f01033e4:	c3                   	ret    

f01033e5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01033e5:	55                   	push   %ebp
f01033e6:	89 e5                	mov    %esp,%ebp
f01033e8:	57                   	push   %edi
f01033e9:	56                   	push   %esi
f01033ea:	53                   	push   %ebx
f01033eb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01033f1:	85 c9                	test   %ecx,%ecx
f01033f3:	74 36                	je     f010342b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01033f5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01033fb:	75 28                	jne    f0103425 <memset+0x40>
f01033fd:	f6 c1 03             	test   $0x3,%cl
f0103400:	75 23                	jne    f0103425 <memset+0x40>
		c &= 0xFF;
f0103402:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103406:	89 d3                	mov    %edx,%ebx
f0103408:	c1 e3 08             	shl    $0x8,%ebx
f010340b:	89 d6                	mov    %edx,%esi
f010340d:	c1 e6 18             	shl    $0x18,%esi
f0103410:	89 d0                	mov    %edx,%eax
f0103412:	c1 e0 10             	shl    $0x10,%eax
f0103415:	09 f0                	or     %esi,%eax
f0103417:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103419:	89 d8                	mov    %ebx,%eax
f010341b:	09 d0                	or     %edx,%eax
f010341d:	c1 e9 02             	shr    $0x2,%ecx
f0103420:	fc                   	cld    
f0103421:	f3 ab                	rep stos %eax,%es:(%edi)
f0103423:	eb 06                	jmp    f010342b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103425:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103428:	fc                   	cld    
f0103429:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010342b:	89 f8                	mov    %edi,%eax
f010342d:	5b                   	pop    %ebx
f010342e:	5e                   	pop    %esi
f010342f:	5f                   	pop    %edi
f0103430:	5d                   	pop    %ebp
f0103431:	c3                   	ret    

f0103432 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103432:	55                   	push   %ebp
f0103433:	89 e5                	mov    %esp,%ebp
f0103435:	57                   	push   %edi
f0103436:	56                   	push   %esi
f0103437:	8b 45 08             	mov    0x8(%ebp),%eax
f010343a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010343d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103440:	39 c6                	cmp    %eax,%esi
f0103442:	73 35                	jae    f0103479 <memmove+0x47>
f0103444:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103447:	39 d0                	cmp    %edx,%eax
f0103449:	73 2e                	jae    f0103479 <memmove+0x47>
		s += n;
		d += n;
f010344b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010344e:	89 d6                	mov    %edx,%esi
f0103450:	09 fe                	or     %edi,%esi
f0103452:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103458:	75 13                	jne    f010346d <memmove+0x3b>
f010345a:	f6 c1 03             	test   $0x3,%cl
f010345d:	75 0e                	jne    f010346d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010345f:	83 ef 04             	sub    $0x4,%edi
f0103462:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103465:	c1 e9 02             	shr    $0x2,%ecx
f0103468:	fd                   	std    
f0103469:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010346b:	eb 09                	jmp    f0103476 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010346d:	83 ef 01             	sub    $0x1,%edi
f0103470:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103473:	fd                   	std    
f0103474:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103476:	fc                   	cld    
f0103477:	eb 1d                	jmp    f0103496 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103479:	89 f2                	mov    %esi,%edx
f010347b:	09 c2                	or     %eax,%edx
f010347d:	f6 c2 03             	test   $0x3,%dl
f0103480:	75 0f                	jne    f0103491 <memmove+0x5f>
f0103482:	f6 c1 03             	test   $0x3,%cl
f0103485:	75 0a                	jne    f0103491 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103487:	c1 e9 02             	shr    $0x2,%ecx
f010348a:	89 c7                	mov    %eax,%edi
f010348c:	fc                   	cld    
f010348d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010348f:	eb 05                	jmp    f0103496 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103491:	89 c7                	mov    %eax,%edi
f0103493:	fc                   	cld    
f0103494:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103496:	5e                   	pop    %esi
f0103497:	5f                   	pop    %edi
f0103498:	5d                   	pop    %ebp
f0103499:	c3                   	ret    

f010349a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010349a:	55                   	push   %ebp
f010349b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010349d:	ff 75 10             	pushl  0x10(%ebp)
f01034a0:	ff 75 0c             	pushl  0xc(%ebp)
f01034a3:	ff 75 08             	pushl  0x8(%ebp)
f01034a6:	e8 87 ff ff ff       	call   f0103432 <memmove>
}
f01034ab:	c9                   	leave  
f01034ac:	c3                   	ret    

f01034ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01034ad:	55                   	push   %ebp
f01034ae:	89 e5                	mov    %esp,%ebp
f01034b0:	56                   	push   %esi
f01034b1:	53                   	push   %ebx
f01034b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034b8:	89 c6                	mov    %eax,%esi
f01034ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01034bd:	eb 1a                	jmp    f01034d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01034bf:	0f b6 08             	movzbl (%eax),%ecx
f01034c2:	0f b6 1a             	movzbl (%edx),%ebx
f01034c5:	38 d9                	cmp    %bl,%cl
f01034c7:	74 0a                	je     f01034d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01034c9:	0f b6 c1             	movzbl %cl,%eax
f01034cc:	0f b6 db             	movzbl %bl,%ebx
f01034cf:	29 d8                	sub    %ebx,%eax
f01034d1:	eb 0f                	jmp    f01034e2 <memcmp+0x35>
		s1++, s2++;
f01034d3:	83 c0 01             	add    $0x1,%eax
f01034d6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01034d9:	39 f0                	cmp    %esi,%eax
f01034db:	75 e2                	jne    f01034bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01034dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034e2:	5b                   	pop    %ebx
f01034e3:	5e                   	pop    %esi
f01034e4:	5d                   	pop    %ebp
f01034e5:	c3                   	ret    

f01034e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01034e6:	55                   	push   %ebp
f01034e7:	89 e5                	mov    %esp,%ebp
f01034e9:	53                   	push   %ebx
f01034ea:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01034ed:	89 c1                	mov    %eax,%ecx
f01034ef:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01034f2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034f6:	eb 0a                	jmp    f0103502 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01034f8:	0f b6 10             	movzbl (%eax),%edx
f01034fb:	39 da                	cmp    %ebx,%edx
f01034fd:	74 07                	je     f0103506 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034ff:	83 c0 01             	add    $0x1,%eax
f0103502:	39 c8                	cmp    %ecx,%eax
f0103504:	72 f2                	jb     f01034f8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103506:	5b                   	pop    %ebx
f0103507:	5d                   	pop    %ebp
f0103508:	c3                   	ret    

f0103509 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103509:	55                   	push   %ebp
f010350a:	89 e5                	mov    %esp,%ebp
f010350c:	57                   	push   %edi
f010350d:	56                   	push   %esi
f010350e:	53                   	push   %ebx
f010350f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103512:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103515:	eb 03                	jmp    f010351a <strtol+0x11>
		s++;
f0103517:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010351a:	0f b6 01             	movzbl (%ecx),%eax
f010351d:	3c 20                	cmp    $0x20,%al
f010351f:	74 f6                	je     f0103517 <strtol+0xe>
f0103521:	3c 09                	cmp    $0x9,%al
f0103523:	74 f2                	je     f0103517 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103525:	3c 2b                	cmp    $0x2b,%al
f0103527:	75 0a                	jne    f0103533 <strtol+0x2a>
		s++;
f0103529:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010352c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103531:	eb 11                	jmp    f0103544 <strtol+0x3b>
f0103533:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103538:	3c 2d                	cmp    $0x2d,%al
f010353a:	75 08                	jne    f0103544 <strtol+0x3b>
		s++, neg = 1;
f010353c:	83 c1 01             	add    $0x1,%ecx
f010353f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103544:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010354a:	75 15                	jne    f0103561 <strtol+0x58>
f010354c:	80 39 30             	cmpb   $0x30,(%ecx)
f010354f:	75 10                	jne    f0103561 <strtol+0x58>
f0103551:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103555:	75 7c                	jne    f01035d3 <strtol+0xca>
		s += 2, base = 16;
f0103557:	83 c1 02             	add    $0x2,%ecx
f010355a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010355f:	eb 16                	jmp    f0103577 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103561:	85 db                	test   %ebx,%ebx
f0103563:	75 12                	jne    f0103577 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103565:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010356a:	80 39 30             	cmpb   $0x30,(%ecx)
f010356d:	75 08                	jne    f0103577 <strtol+0x6e>
		s++, base = 8;
f010356f:	83 c1 01             	add    $0x1,%ecx
f0103572:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103577:	b8 00 00 00 00       	mov    $0x0,%eax
f010357c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010357f:	0f b6 11             	movzbl (%ecx),%edx
f0103582:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103585:	89 f3                	mov    %esi,%ebx
f0103587:	80 fb 09             	cmp    $0x9,%bl
f010358a:	77 08                	ja     f0103594 <strtol+0x8b>
			dig = *s - '0';
f010358c:	0f be d2             	movsbl %dl,%edx
f010358f:	83 ea 30             	sub    $0x30,%edx
f0103592:	eb 22                	jmp    f01035b6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103594:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103597:	89 f3                	mov    %esi,%ebx
f0103599:	80 fb 19             	cmp    $0x19,%bl
f010359c:	77 08                	ja     f01035a6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010359e:	0f be d2             	movsbl %dl,%edx
f01035a1:	83 ea 57             	sub    $0x57,%edx
f01035a4:	eb 10                	jmp    f01035b6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01035a6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01035a9:	89 f3                	mov    %esi,%ebx
f01035ab:	80 fb 19             	cmp    $0x19,%bl
f01035ae:	77 16                	ja     f01035c6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01035b0:	0f be d2             	movsbl %dl,%edx
f01035b3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01035b6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01035b9:	7d 0b                	jge    f01035c6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01035bb:	83 c1 01             	add    $0x1,%ecx
f01035be:	0f af 45 10          	imul   0x10(%ebp),%eax
f01035c2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01035c4:	eb b9                	jmp    f010357f <strtol+0x76>

	if (endptr)
f01035c6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01035ca:	74 0d                	je     f01035d9 <strtol+0xd0>
		*endptr = (char *) s;
f01035cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035cf:	89 0e                	mov    %ecx,(%esi)
f01035d1:	eb 06                	jmp    f01035d9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01035d3:	85 db                	test   %ebx,%ebx
f01035d5:	74 98                	je     f010356f <strtol+0x66>
f01035d7:	eb 9e                	jmp    f0103577 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01035d9:	89 c2                	mov    %eax,%edx
f01035db:	f7 da                	neg    %edx
f01035dd:	85 ff                	test   %edi,%edi
f01035df:	0f 45 c2             	cmovne %edx,%eax
}
f01035e2:	5b                   	pop    %ebx
f01035e3:	5e                   	pop    %esi
f01035e4:	5f                   	pop    %edi
f01035e5:	5d                   	pop    %ebp
f01035e6:	c3                   	ret    
f01035e7:	66 90                	xchg   %ax,%ax
f01035e9:	66 90                	xchg   %ax,%ax
f01035eb:	66 90                	xchg   %ax,%ax
f01035ed:	66 90                	xchg   %ax,%ax
f01035ef:	90                   	nop

f01035f0 <__udivdi3>:
f01035f0:	55                   	push   %ebp
f01035f1:	57                   	push   %edi
f01035f2:	56                   	push   %esi
f01035f3:	53                   	push   %ebx
f01035f4:	83 ec 1c             	sub    $0x1c,%esp
f01035f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01035fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01035ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103603:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103607:	85 f6                	test   %esi,%esi
f0103609:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010360d:	89 ca                	mov    %ecx,%edx
f010360f:	89 f8                	mov    %edi,%eax
f0103611:	75 3d                	jne    f0103650 <__udivdi3+0x60>
f0103613:	39 cf                	cmp    %ecx,%edi
f0103615:	0f 87 c5 00 00 00    	ja     f01036e0 <__udivdi3+0xf0>
f010361b:	85 ff                	test   %edi,%edi
f010361d:	89 fd                	mov    %edi,%ebp
f010361f:	75 0b                	jne    f010362c <__udivdi3+0x3c>
f0103621:	b8 01 00 00 00       	mov    $0x1,%eax
f0103626:	31 d2                	xor    %edx,%edx
f0103628:	f7 f7                	div    %edi
f010362a:	89 c5                	mov    %eax,%ebp
f010362c:	89 c8                	mov    %ecx,%eax
f010362e:	31 d2                	xor    %edx,%edx
f0103630:	f7 f5                	div    %ebp
f0103632:	89 c1                	mov    %eax,%ecx
f0103634:	89 d8                	mov    %ebx,%eax
f0103636:	89 cf                	mov    %ecx,%edi
f0103638:	f7 f5                	div    %ebp
f010363a:	89 c3                	mov    %eax,%ebx
f010363c:	89 d8                	mov    %ebx,%eax
f010363e:	89 fa                	mov    %edi,%edx
f0103640:	83 c4 1c             	add    $0x1c,%esp
f0103643:	5b                   	pop    %ebx
f0103644:	5e                   	pop    %esi
f0103645:	5f                   	pop    %edi
f0103646:	5d                   	pop    %ebp
f0103647:	c3                   	ret    
f0103648:	90                   	nop
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	39 ce                	cmp    %ecx,%esi
f0103652:	77 74                	ja     f01036c8 <__udivdi3+0xd8>
f0103654:	0f bd fe             	bsr    %esi,%edi
f0103657:	83 f7 1f             	xor    $0x1f,%edi
f010365a:	0f 84 98 00 00 00    	je     f01036f8 <__udivdi3+0x108>
f0103660:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103665:	89 f9                	mov    %edi,%ecx
f0103667:	89 c5                	mov    %eax,%ebp
f0103669:	29 fb                	sub    %edi,%ebx
f010366b:	d3 e6                	shl    %cl,%esi
f010366d:	89 d9                	mov    %ebx,%ecx
f010366f:	d3 ed                	shr    %cl,%ebp
f0103671:	89 f9                	mov    %edi,%ecx
f0103673:	d3 e0                	shl    %cl,%eax
f0103675:	09 ee                	or     %ebp,%esi
f0103677:	89 d9                	mov    %ebx,%ecx
f0103679:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010367d:	89 d5                	mov    %edx,%ebp
f010367f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103683:	d3 ed                	shr    %cl,%ebp
f0103685:	89 f9                	mov    %edi,%ecx
f0103687:	d3 e2                	shl    %cl,%edx
f0103689:	89 d9                	mov    %ebx,%ecx
f010368b:	d3 e8                	shr    %cl,%eax
f010368d:	09 c2                	or     %eax,%edx
f010368f:	89 d0                	mov    %edx,%eax
f0103691:	89 ea                	mov    %ebp,%edx
f0103693:	f7 f6                	div    %esi
f0103695:	89 d5                	mov    %edx,%ebp
f0103697:	89 c3                	mov    %eax,%ebx
f0103699:	f7 64 24 0c          	mull   0xc(%esp)
f010369d:	39 d5                	cmp    %edx,%ebp
f010369f:	72 10                	jb     f01036b1 <__udivdi3+0xc1>
f01036a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01036a5:	89 f9                	mov    %edi,%ecx
f01036a7:	d3 e6                	shl    %cl,%esi
f01036a9:	39 c6                	cmp    %eax,%esi
f01036ab:	73 07                	jae    f01036b4 <__udivdi3+0xc4>
f01036ad:	39 d5                	cmp    %edx,%ebp
f01036af:	75 03                	jne    f01036b4 <__udivdi3+0xc4>
f01036b1:	83 eb 01             	sub    $0x1,%ebx
f01036b4:	31 ff                	xor    %edi,%edi
f01036b6:	89 d8                	mov    %ebx,%eax
f01036b8:	89 fa                	mov    %edi,%edx
f01036ba:	83 c4 1c             	add    $0x1c,%esp
f01036bd:	5b                   	pop    %ebx
f01036be:	5e                   	pop    %esi
f01036bf:	5f                   	pop    %edi
f01036c0:	5d                   	pop    %ebp
f01036c1:	c3                   	ret    
f01036c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01036c8:	31 ff                	xor    %edi,%edi
f01036ca:	31 db                	xor    %ebx,%ebx
f01036cc:	89 d8                	mov    %ebx,%eax
f01036ce:	89 fa                	mov    %edi,%edx
f01036d0:	83 c4 1c             	add    $0x1c,%esp
f01036d3:	5b                   	pop    %ebx
f01036d4:	5e                   	pop    %esi
f01036d5:	5f                   	pop    %edi
f01036d6:	5d                   	pop    %ebp
f01036d7:	c3                   	ret    
f01036d8:	90                   	nop
f01036d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01036e0:	89 d8                	mov    %ebx,%eax
f01036e2:	f7 f7                	div    %edi
f01036e4:	31 ff                	xor    %edi,%edi
f01036e6:	89 c3                	mov    %eax,%ebx
f01036e8:	89 d8                	mov    %ebx,%eax
f01036ea:	89 fa                	mov    %edi,%edx
f01036ec:	83 c4 1c             	add    $0x1c,%esp
f01036ef:	5b                   	pop    %ebx
f01036f0:	5e                   	pop    %esi
f01036f1:	5f                   	pop    %edi
f01036f2:	5d                   	pop    %ebp
f01036f3:	c3                   	ret    
f01036f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036f8:	39 ce                	cmp    %ecx,%esi
f01036fa:	72 0c                	jb     f0103708 <__udivdi3+0x118>
f01036fc:	31 db                	xor    %ebx,%ebx
f01036fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103702:	0f 87 34 ff ff ff    	ja     f010363c <__udivdi3+0x4c>
f0103708:	bb 01 00 00 00       	mov    $0x1,%ebx
f010370d:	e9 2a ff ff ff       	jmp    f010363c <__udivdi3+0x4c>
f0103712:	66 90                	xchg   %ax,%ax
f0103714:	66 90                	xchg   %ax,%ax
f0103716:	66 90                	xchg   %ax,%ax
f0103718:	66 90                	xchg   %ax,%ax
f010371a:	66 90                	xchg   %ax,%ax
f010371c:	66 90                	xchg   %ax,%ax
f010371e:	66 90                	xchg   %ax,%ax

f0103720 <__umoddi3>:
f0103720:	55                   	push   %ebp
f0103721:	57                   	push   %edi
f0103722:	56                   	push   %esi
f0103723:	53                   	push   %ebx
f0103724:	83 ec 1c             	sub    $0x1c,%esp
f0103727:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010372b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010372f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103733:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103737:	85 d2                	test   %edx,%edx
f0103739:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010373d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103741:	89 f3                	mov    %esi,%ebx
f0103743:	89 3c 24             	mov    %edi,(%esp)
f0103746:	89 74 24 04          	mov    %esi,0x4(%esp)
f010374a:	75 1c                	jne    f0103768 <__umoddi3+0x48>
f010374c:	39 f7                	cmp    %esi,%edi
f010374e:	76 50                	jbe    f01037a0 <__umoddi3+0x80>
f0103750:	89 c8                	mov    %ecx,%eax
f0103752:	89 f2                	mov    %esi,%edx
f0103754:	f7 f7                	div    %edi
f0103756:	89 d0                	mov    %edx,%eax
f0103758:	31 d2                	xor    %edx,%edx
f010375a:	83 c4 1c             	add    $0x1c,%esp
f010375d:	5b                   	pop    %ebx
f010375e:	5e                   	pop    %esi
f010375f:	5f                   	pop    %edi
f0103760:	5d                   	pop    %ebp
f0103761:	c3                   	ret    
f0103762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103768:	39 f2                	cmp    %esi,%edx
f010376a:	89 d0                	mov    %edx,%eax
f010376c:	77 52                	ja     f01037c0 <__umoddi3+0xa0>
f010376e:	0f bd ea             	bsr    %edx,%ebp
f0103771:	83 f5 1f             	xor    $0x1f,%ebp
f0103774:	75 5a                	jne    f01037d0 <__umoddi3+0xb0>
f0103776:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010377a:	0f 82 e0 00 00 00    	jb     f0103860 <__umoddi3+0x140>
f0103780:	39 0c 24             	cmp    %ecx,(%esp)
f0103783:	0f 86 d7 00 00 00    	jbe    f0103860 <__umoddi3+0x140>
f0103789:	8b 44 24 08          	mov    0x8(%esp),%eax
f010378d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103791:	83 c4 1c             	add    $0x1c,%esp
f0103794:	5b                   	pop    %ebx
f0103795:	5e                   	pop    %esi
f0103796:	5f                   	pop    %edi
f0103797:	5d                   	pop    %ebp
f0103798:	c3                   	ret    
f0103799:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01037a0:	85 ff                	test   %edi,%edi
f01037a2:	89 fd                	mov    %edi,%ebp
f01037a4:	75 0b                	jne    f01037b1 <__umoddi3+0x91>
f01037a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01037ab:	31 d2                	xor    %edx,%edx
f01037ad:	f7 f7                	div    %edi
f01037af:	89 c5                	mov    %eax,%ebp
f01037b1:	89 f0                	mov    %esi,%eax
f01037b3:	31 d2                	xor    %edx,%edx
f01037b5:	f7 f5                	div    %ebp
f01037b7:	89 c8                	mov    %ecx,%eax
f01037b9:	f7 f5                	div    %ebp
f01037bb:	89 d0                	mov    %edx,%eax
f01037bd:	eb 99                	jmp    f0103758 <__umoddi3+0x38>
f01037bf:	90                   	nop
f01037c0:	89 c8                	mov    %ecx,%eax
f01037c2:	89 f2                	mov    %esi,%edx
f01037c4:	83 c4 1c             	add    $0x1c,%esp
f01037c7:	5b                   	pop    %ebx
f01037c8:	5e                   	pop    %esi
f01037c9:	5f                   	pop    %edi
f01037ca:	5d                   	pop    %ebp
f01037cb:	c3                   	ret    
f01037cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01037d0:	8b 34 24             	mov    (%esp),%esi
f01037d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01037d8:	89 e9                	mov    %ebp,%ecx
f01037da:	29 ef                	sub    %ebp,%edi
f01037dc:	d3 e0                	shl    %cl,%eax
f01037de:	89 f9                	mov    %edi,%ecx
f01037e0:	89 f2                	mov    %esi,%edx
f01037e2:	d3 ea                	shr    %cl,%edx
f01037e4:	89 e9                	mov    %ebp,%ecx
f01037e6:	09 c2                	or     %eax,%edx
f01037e8:	89 d8                	mov    %ebx,%eax
f01037ea:	89 14 24             	mov    %edx,(%esp)
f01037ed:	89 f2                	mov    %esi,%edx
f01037ef:	d3 e2                	shl    %cl,%edx
f01037f1:	89 f9                	mov    %edi,%ecx
f01037f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01037fb:	d3 e8                	shr    %cl,%eax
f01037fd:	89 e9                	mov    %ebp,%ecx
f01037ff:	89 c6                	mov    %eax,%esi
f0103801:	d3 e3                	shl    %cl,%ebx
f0103803:	89 f9                	mov    %edi,%ecx
f0103805:	89 d0                	mov    %edx,%eax
f0103807:	d3 e8                	shr    %cl,%eax
f0103809:	89 e9                	mov    %ebp,%ecx
f010380b:	09 d8                	or     %ebx,%eax
f010380d:	89 d3                	mov    %edx,%ebx
f010380f:	89 f2                	mov    %esi,%edx
f0103811:	f7 34 24             	divl   (%esp)
f0103814:	89 d6                	mov    %edx,%esi
f0103816:	d3 e3                	shl    %cl,%ebx
f0103818:	f7 64 24 04          	mull   0x4(%esp)
f010381c:	39 d6                	cmp    %edx,%esi
f010381e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103822:	89 d1                	mov    %edx,%ecx
f0103824:	89 c3                	mov    %eax,%ebx
f0103826:	72 08                	jb     f0103830 <__umoddi3+0x110>
f0103828:	75 11                	jne    f010383b <__umoddi3+0x11b>
f010382a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010382e:	73 0b                	jae    f010383b <__umoddi3+0x11b>
f0103830:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103834:	1b 14 24             	sbb    (%esp),%edx
f0103837:	89 d1                	mov    %edx,%ecx
f0103839:	89 c3                	mov    %eax,%ebx
f010383b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010383f:	29 da                	sub    %ebx,%edx
f0103841:	19 ce                	sbb    %ecx,%esi
f0103843:	89 f9                	mov    %edi,%ecx
f0103845:	89 f0                	mov    %esi,%eax
f0103847:	d3 e0                	shl    %cl,%eax
f0103849:	89 e9                	mov    %ebp,%ecx
f010384b:	d3 ea                	shr    %cl,%edx
f010384d:	89 e9                	mov    %ebp,%ecx
f010384f:	d3 ee                	shr    %cl,%esi
f0103851:	09 d0                	or     %edx,%eax
f0103853:	89 f2                	mov    %esi,%edx
f0103855:	83 c4 1c             	add    $0x1c,%esp
f0103858:	5b                   	pop    %ebx
f0103859:	5e                   	pop    %esi
f010385a:	5f                   	pop    %edi
f010385b:	5d                   	pop    %ebp
f010385c:	c3                   	ret    
f010385d:	8d 76 00             	lea    0x0(%esi),%esi
f0103860:	29 f9                	sub    %edi,%ecx
f0103862:	19 d6                	sbb    %edx,%esi
f0103864:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103868:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010386c:	e9 18 ff ff ff       	jmp    f0103789 <__umoddi3+0x69>
