/*******************************************************************************
Copyright (c) 2015, The OpenBLAS Project
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.
3. Neither the name of the OpenBLAS project nor the names of
its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE OPENBLAS PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

#define ASSEMBLER
#include "common.h"

#define	N	x0	/* vector length */
#define	X	x1	/* X vector address */
#define	INC_X	x2	/* X stride */
#define	Y	x3	/* Y vector address */
#define	INC_Y	x4	/* Y stride */
#define I	x5	/* loop variable */

/*******************************************************************************
* Macro definitions
*******************************************************************************/

#if !defined(DOUBLE)
#define TMPF	s0
#define TMPVF	{v0.s}[0]
#define SZ	4
#else
#define TMPF	d0
#define TMPVF	{v0.d}[0]
#define SZ	8
#endif

/******************************************************************************/

.macro KERNEL_F1

#if !defined(COMPLEX)
	ldr	TMPF, [X], #SZ
	str	TMPF, [Y], #SZ
#else
#if !defined(DOUBLE)
	ld1	{v0.2s}, [X], #8
	st1	{v0.2s}, [Y], #8
#else
	ld1	{v0.2d}, [X], #16
	st1	{v0.2d}, [Y], #16
#endif
#endif

.endm

.macro KERNEL_F4

#if !defined(COMPLEX)
#if !defined(DOUBLE)
	ld1	{v0.4s}, [X], #16
	st1	{v0.4s}, [Y], #16
#else // DOUBLE
	ld1	{v0.4s}, [X], #16
	ld1	{v1.4s}, [X], #16
	st1	{v0.4s}, [Y], #16
	st1	{v1.4s}, [Y], #16
#endif
#else // COMPLEX
#if !defined(DOUBLE)
	ld1	{v0.4s}, [X], #16
	ld1	{v1.4s}, [X], #16
	st1	{v0.4s}, [Y], #16
	st1	{v1.4s}, [Y], #16
#else // DOUBLE
	ld1	{v0.4s}, [X], #16
	ld1	{v1.4s}, [X], #16
	ld1	{v2.4s}, [X], #16
	ld1	{v3.4s}, [X], #16
	st1	{v0.4s}, [Y], #16
	st1	{v1.4s}, [Y], #16
	st1	{v2.4s}, [Y], #16
	st1	{v3.4s}, [Y], #16
#endif
#endif

.endm

.macro INIT_S

#if !defined(COMPLEX)
#if !defined(DOUBLE)
	lsl	INC_X, INC_X, #2
	lsl	INC_Y, INC_Y, #2
#else
	lsl	INC_X, INC_X, #3
	lsl	INC_Y, INC_Y, #3
#endif
#else
#if !defined(DOUBLE)
	lsl	INC_X, INC_X, #3
	lsl	INC_Y, INC_Y, #3
#else
	lsl	INC_X, INC_X, #4
	lsl	INC_Y, INC_Y, #4
#endif
#endif

.endm

.macro KERNEL_S1

#if !defined(COMPLEX)
#if !defined(DOUBLE)
	ldr	w10, [X]
	add	X, X, INC_X
	str	w10, [Y]
	add	Y, Y, INC_Y
#else
	ldr	x10, [X]
	add	X, X, INC_X
	str	x10, [Y]
	add	Y, Y, INC_Y
#endif
#else
#if !defined(DOUBLE)
	ld1	{v0.2s}, [X]
	add	X, X, INC_X
	st1	{v0.2s}, [Y]
	add	Y, Y, INC_Y
#else
	ld1	{v0.2d}, [X]
	add	X, X, INC_X
	st1	{v0.2d}, [Y]
	add	Y, Y, INC_Y
#endif
#endif

.endm

/*******************************************************************************
* End of macro definitions
*******************************************************************************/

	PROLOGUE

	cmp	N, xzr
	ble	copy_kernel_L999

	cmp	INC_X, #1
	bne	copy_kernel_S_BEGIN
	cmp	INC_Y, #1
	bne	copy_kernel_S_BEGIN

copy_kernel_F_BEGIN:

	asr	I, N, #2
	cmp	I, xzr
	beq	copy_kernel_F1

copy_kernel_F4:

	KERNEL_F4

	subs	I, I, #1
	bne	copy_kernel_F4

copy_kernel_F1:

	ands	I, N, #3
	ble	copy_kernel_L999

copy_kernel_F10:

	KERNEL_F1

	subs    I, I, #1
        bne     copy_kernel_F10

	mov	w0, wzr
	ret

copy_kernel_S_BEGIN:

	INIT_S

	asr	I, N, #2
	cmp	I, xzr
	ble	copy_kernel_S1

copy_kernel_S4:

	KERNEL_S1
	KERNEL_S1
	KERNEL_S1
	KERNEL_S1

	subs	I, I, #1
	bne	copy_kernel_S4

copy_kernel_S1:

	ands	I, N, #3
	ble	copy_kernel_L999

copy_kernel_S10:

	KERNEL_S1

	subs    I, I, #1
        bne     copy_kernel_S10

copy_kernel_L999:

	mov	w0, wzr
	ret

	EPILOGUE
