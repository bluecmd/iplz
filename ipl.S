.section ".ipl","a"
.global _ipl

_ipl:
	# See 17-17 in Principles of Operation for IPL details
	#
	# Program-Status Word
	# ┌─┬─┬─┬─┬─┬─┬─┬─┬───────┬─┬─┬─┬─┬───┬───┬───────┬─────────────┬─┐
	# │ │ │ │ │ │ │I│E│       │ │ │ │ │   │   │ Prog  │             │E│
	# │0│R│0│0│0│T│O│X│ Key   │1│M│W│P│A S│C C│ Mask  │ 0 0 0 0 0 0 │A│
	# └─┴─┴─┴─┴─┴─┴─┴─┴───────┴─┴─┴─┴─┴───┴───┴───────┴─────────────┴─┘
	# 0          5    8       12      16  18  20     24              31
	# ┌─┬─────────────────────────────────────────────────────────────┐
	# │B│                                                             │
	# │A│ Instruction Address                                         │
	# └─┴─────────────────────────────────────────────────────────────┘
	# 32                                                             63
	#

	# Format-0 CCW
	# ┌────────┬────────────────────────────────────────┐
	# │Cmd Code│ Data Address                           │
	# └────────┴────────────────────────────────────────┘
	# 0        8                                       31
	# ┌─────────────┬─┬────────┬────────────────────────┐
	# │ Flags       │0│////////│ Count                  │
	# └─────────────┴─┴────────┴────────────────────────┘
	# 32            39        48                       63
	#
	# ┌───────────────────┬──────────────────────────┐
	# │ Code              │ Command                  │
	# ├───────────────────┼──────────────────────────┤
	# │ x x x x   0 0 0 0 │ Invalid                  │
	# │ m m m m   m m 0 1 │ Write                    │
	# │ m m m m   m m 1 0 │ Read                     │
	# │ m m m m   1 1 0 0 │ Read backward            │
	# │ m m m m   m m 1 1 │ Control                  │
	# │ m m m m   0 1 0 0 │ Sense                    │
	# │ 1 1 1 0   0 1 0 0 │ Sense ID                 │
	# │ x x x x   1 0 0 0 │ Transfer in channel (1)  │
	# │ 0 0 0 0   1 0 0 0 │ Transfer in channel (2)  │
	# │ m m m m   1 0 0 0 │ Invalid (3)              │
	# ├───────────────────┴──────────────────────────┤
	# │Explanation:                                  │
	# │ m Modifier bit                               │
	# │ x Ignored                                    │
	# │ (1) Format-0 CCW                             │
	# │ (2) Format-1 CCW                             │
	# │ (3) Format-1 CCW with any of bits -3 nonzero │
	# └──────────────────────────────────────────────┘
	#
	# Flags
	# ┌─┬─┬─┬─┬─┬─┬─┬─┐
	# │ │ │S│S│P│I│ │ │
	# │C│C│L│K│C│D│ │ │
	# │D│C│I│P│I│A│S│0│
	# └─┴─┴─┴─┴─┴─┴─┴─┘
	# 32              39 (in format-0 CCW)
	#

	# It seems that the CCWs used at least for IPLing can be *max* 80 bytes
	# long. Makes sense, as that's one punch-card, but it would be nice to find
	# a reference source for this. Possibly in the 3505 reference.

	# Load initial basic code and then load the rest from higher level code
	# My understanding how this works is like this:
	# The format of the initial IPL card is that it contains:
	#  - IPL PSW that will be applied after IPL CCWs execute
	#  - 2x IPL CCWs
	# The implied CCW that the IPL process itself uses is documented to be
	# Count=24, so I think it should only advance the read pointer by 24, but
	# it seems like it advances it with a full card (80 bytes). That might be
	# my misunderstanding however.
	#
	# Anyway, what the Linux kernel does and what we mimic is that we start two
	# 80-byte loads to the address straight after our two CCWs (0x18) where we
	# load more CCWs that we can then use to copy data into storage.
	# This means that during the very early IPL stage we are misaligned a bit;
	# 0x50 is loaded to 0x18, but those are only for two CCWs so we should be fine.

	.long   0x00080000,0x80000000+_init  # IPL PSW (see "LOAD PSW")
	.long   0x02000018,0x60000050 # Load two cards of extra CCws
	.long   0x02000068,0x60000050 #
.org 80 # The rest of the first card is ignored (CCW read result in card feed)
	.long   0x02000200,0x60000001 # Skip the rest of the cards up until 0x230
	.long   0x02000200,0x60000001
	.long   0x02000200,0x60000001
	.long   0x02000200,0x60000001
	.long   0x02000230,0x60000050 # Load our loader program
	.long   0x02000280,0x60000050
	.long   0x020002d0,0x20000050
	# We have now loaded up to 0x320

	# "The IPL program should not be placed in the low 512 bytes of storage since
	# that area is reserved as described in a programming note under
	# “Compatibility between z/Architecture and ESA/390” on page 1-17."
	# Align to a punch card boundary (80 bytes)

	# This section is put into 0x230 by the linker script
.section ".load","ax"

	# Any function between here and 0x320 will be loaded and responsible to
	# move the other code into memory
_init:
	# Switch CP0 to z/Arch / ESAME (64-bit) mode
	slr   %r0,%r0
	lhi   %r1,2  # Mode 2 = ESAME
	sigp  %r1,%r0,0x12
	sam64
	lhi   %r15,.Lload_stack_end
	j     load

	# Reserve 8 KiB of temporary stack for load CCW code
.section ".load.stack","aw"
.align 16
.space 0x1000, 0xa5
.Lload_stack_end:
