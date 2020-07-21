#include <string.h>
#include <stdint.h>
#include <stdio.h>

#include <font/font.h>

#ifdef CONFIG_FONT_SIMSUN

#define FONT_DATA_MAX   (2048 + 16)
#define FONT_NAME       "simsun"
#define FONT_COPYRIGHT  "Microsoft Windows"

static uint8_t __attribute__((aligned(16))) font_data_simsun[FONT_DATA_MAX] = {
	/* 0 0x00 '^@' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 1 0x01 '^A' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 2 0x02 '^B' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 3 0x03 '^C' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 4 0x04 '^D' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 5 0x05 '^E' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 6 0x06 '^F' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 7 0x07 '^G' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 8 0x08 '^H' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 9 0x09 '^I' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 10 0x0a '^J' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 11 0x0b '^K' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 12 0x0c '^L' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 13 0x0d '^M' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 14 0x0e '^N' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 15 0x0f '^O' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 16 0x10 '^P' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 17 0x11 '^Q' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 18 0x12 '^R' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 19 0x13 '^S' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 20 0x14 '^T' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 21 0x15 '^U' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 22 0x16 '^V' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 23 0x17 '^W' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 24 0x18 '^X' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 25 0x19 '^Y' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 26 0x1a '^Z' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 27 0x1b '^[' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 28 0x1c '^\' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 29 0x1d '^]' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 30 0x1e '^^' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 31 0x1f '^_' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 32 0x20 ' ' */
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//!
	0b00000000,
	0b00000000,
	0b00000000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00000000,
	0b00000000,
	0b00011000,
	0b00011000,
	0b00000000,
	0b00000000,
	//"
	0b00000000,
	0b01100110,
	0b01100110,
	0b00100100,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//#
	0b00000000,
	0b00000000,
	0b00000000,
	0b00100100,
	0b00100100,
	0b00100100,
	0b11111110,
	0b01001000,
	0b01001000,
	0b01001000,
	0b11111110,
	0b01001000,
	0b01001000,
	0b01001000,
	0b00000000,
	0b00000000,
	//$
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//%
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//&
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//'
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//(
	0b00000000,
	0b00000100,
	0b00001000,
	0b00010000,
	0b00010000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00010000,
	0b00010000,
	0b00001000,
	0b00000100,
	0b00000000,
	//)
	0b00000000,
	0b00100000,
	0b00010000,
	0b00001000,
	0b00001000,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00001000,
	0b00001000,
	0b00010000,
	0b00100000,
	0b00000000,
	//*
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//+
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00001110,
	0b00001100,
	0b00011000,
	0b00100000,
	//-
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//.
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00110000,
	0b00110000,
	0b00000000,
	0b00000000,
	/* 47 0x2f '/' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	//0
	0b00000000,
	0b00000000,
	0b00000000,
	0b00011000,
	0b00100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100100,
	0b00011000,
	0b00000000,
	0b00000000,
	//1
	0b00000000,
	0b00000000,
	0b00000000,
	0b00010000,
	0b01110000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b01111100,
	0b00000000,
	0b00000000,
	//2
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00000100,
	0b00000100,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000010,
	0b01111110,
	0b00000000,
	0b00000000,
	//3
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000010,
	0b01000010,
	0b00000100,
	0b00011000,
	0b00000100,
	0b00000010,
	0b00000010,
	0b01000010,
	0b01000100,
	0b00111000,
	0b00000000,
	0b00000000,
	//4
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000100,
	0b00001100,
	0b00010100,
	0b00100100,
	0b00100100,
	0b01000100,
	0b01000100,
	0b01111110,
	0b00000100,
	0b00000100,
	0b00011110,
	0b00000000,
	0b00000000,
	//5
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01011000,
	0b01100100,
	0b00000010,
	0b00000010,
	0b01000010,
	0b01000100,
	0b00111000,
	0b00000000,
	0b00000000,
	//6
	0b00000000,
	0b00000000,
	0b00000000,
	0b00011100,
	0b00100100,
	0b01000000,
	0b01000000,
	0b01011000,
	0b01100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100100,
	0b00011000,
	0b00000000,
	0b00000000,
	//7
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b01000100,
	0b01000100,
	0b00001000,
	0b00001000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00000000,
	0b00000000,
	//8
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100100,
	0b00011000,
	0b00100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00111100,
	0b00000000,
	0b00000000,
	//9
	0b00000000,
	0b00000000,
	0b00000000,
	0b00011000,
	0b00100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100110,
	0b00011010,
	0b00000010,
	0b00000010,
	0b00100100,
	0b00111000,
	0b00000000,
	0b00000000,
	//:
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00110000,
	0b00110000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00110000,
	0b00110000,
	0b00000000,
	0b00000000,
	//;
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00100000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00100000,
	0b00100000,
	0b01000000,
	//<
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000010,
	0b00000100,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000000,
	0b00100000,
	0b00010000,
	0b00001000,
	0b00000100,
	0b00000010,
	0b00000000,
	0b00000000,
	//=
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//>
	0b00000000,
	0b00000000,
	0b00000000,
	0b01000000,
	0b00100000,
	0b00010000,
	0b00001000,
	0b00000100,
	0b00000010,
	0b00000100,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000000,
	0b00000000,
	0b00000000,
	/* 63 0x3f '?' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 64 0x40 '@' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 65 0x41 'A' */
	0b00000000,
	0b00000000,
	0b00000000,
	0b00010000,
	0b00010000,
	0b00011000,
	0b00101000,
	0b00101000,
	0b00100100,
	0b00111100,
	0b01000100,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	/* 66 0x42 'B' */
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111000,
	0b01000100,
	0b01000100,
	0b01000100,
	0b01111000,
	0b01000100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000100,
	0b11111000,
	0b00000000,
	0b00000000,
	//C
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111110,
	0b01000010,
	0b01000010,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b01000010,
	0b01000100,
	0b00111000,
	0b00000000,
	0b00000000,
	//D
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111000,
	0b01000100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000100,
	0b11111000,
	0b00000000,
	0b00000000,
	//E
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111100,
	0b01000010,
	0b01001000,
	0b01001000,
	0b01111000,
	0b01001000,
	0b01001000,
	0b01000000,
	0b01000010,
	0b01000010,
	0b11111100,
	0b00000000,
	0b00000000,
	//F
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111100,
	0b01000010,
	0b01001000,
	0b01001000,
	0b01111000,
	0b01001000,
	0b01001000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b11100000,
	0b00000000,
	0b00000000,
	//G
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000100,
	0b01000100,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10001110,
	0b10000100,
	0b01000100,
	0b01000100,
	0b00111000,
	0b00000000,
	0b00000000,
	//H
	0b00000000,
	0b00000000,
	0b00000000,
	0b11100111,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01111110,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	//I
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111100,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b01111100,
	0b00000000,
	0b00000000,
	//J
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111110,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b00001000,
	0b10001000,
	0b11110000,
	//K
	0b00000000,
	0b00000000,
	0b00000000,
	0b11101110,
	0b01000100,
	0b01001000,
	0b01010000,
	0b01110000,
	0b01010000,
	0b01001000,
	0b01001000,
	0b01000100,
	0b01000100,
	0b11101110,
	0b00000000,
	0b00000000,
	//L
	0b00000000,
	0b00000000,
	0b00000000,
	0b11100000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000010,
	0b11111110,
	0b00000000,
	0b00000000,
	//M
	0b00000000,
	0b00000000,
	0b00000000,
	0b11101110,
	0b01101100,
	0b01101100,
	0b01101100,
	0b01101100,
	0b01010100,
	0b01010100,
	0b01010100,
	0b01010100,
	0b01010100,
	0b11010110,
	0b00000000,
	0b00000000,
	//N
	0b00000000,
	0b00000000,
	0b00000000,
	0b11000111,
	0b01100010,
	0b01100010,
	0b01010010,
	0b01010010,
	0b01001010,
	0b01001010,
	0b01001010,
	0b01000110,
	0b01000110,
	0b11100010,
	0b00000000,
	0b00000000,
	//O
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111000,
	0b01000100,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b01000100,
	0b00111000,
	0b00000000,
	0b00000000,
	//P
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01111100,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b11100000,
	0b00000000,
	0b00000000,
	//Q
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111000,
	0b01000100,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10000010,
	0b10110010,
	0b11001010,
	0b01001100,
	0b00111000,
	0b00000110,
	0b00000000,
	//R
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01111100,
	0b01001000,
	0b01001000,
	0b01000100,
	0b01000100,
	0b01000010,
	0b11100011,
	0b00000000,
	0b00000000,
	//S
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111110,
	0b01000010,
	0b01000010,
	0b01000000,
	0b00100000,
	0b00011000,
	0b00000100,
	0b00000010,
	0b01000010,
	0b01000010,
	0b01111100,
	0b00000000,
	0b00000000,
	//T
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111110,
	0b10010010,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00111000,
	0b00000000,
	0b00000000,
	//U
	0b00000000,
	0b00000000,
	0b00000000,
	0b11100111,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00111100,
	0b00000000,
	0b00000000,
	//V
	0b00000000,
	0b11100111,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100100,
	0b00100100,
	0b00100100,
	0b00100100,
	0b00100100,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00000000,
	0b00000000,
	//W
	0b00000000,
	0b00000000,
	0b00000000,
	0b11010110,
	0b10010010,
	0b10010010,
	0b10010010,
	0b10010010,
	0b10101010,
	0b10101010,
	0b01101100,
	0b01000100,
	0b01000100,
	0b01000100,
	0b00000000,
	0b00000000,
	//X
	0b00000000,
	0b00000000,
	0b00000000,
	0b11100111,
	0b01000010,
	0b00100100,
	0b00100100,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00100100,
	0b00100100,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	//Y
	0b00000000,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00100100,
	0b00100100,
	0b00100100,
	0b00100100,
	0b01111110,
	0b01000010,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	//Z
	0b00000000,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00100100,
	0b00100100,
	0b00100100,
	0b00100100,
	0b01111110,
	0b01000010,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	//[
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//"\"
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//]
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//^
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//_
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111111,
	0b00000000,
	0b00000000,
	//'
	0b11111111,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b10000001,
	0b11111111,
	//a
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111000,
	0b10000100,
	0b00111100,
	0b01000100,
	0b10000100,
	0b10000100,
	0b01111110,
	0b00000000,
	0b00000000,
	//b
	0b00000000,
	0b00000000,
	0b00000000,
	0b11000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01011000,
	0b01100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01100100,
	0b01011000,
	0b00000000,
	0b00000000,
	//c
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00011100,
	0b00100010,
	0b01000000,
	0b01000000,
	0b01000000,
	0b00100010,
	0b00011100,
	0b00000000,
	0b00000000,
	//d
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000110,
	0b00000010,
	0b00000010,
	0b00000010,
	0b00011110,
	0b00100010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00100110,
	0b00011011,
	0b00000000,
	0b00000000,
	//e
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000010,
	0b01111110,
	0b01000000,
	0b01000000,
	0b01000010,
	0b00111100,
	0b00000000,
	0b00000000,
	//f
	0b00000000,
	0b00000000,
	0b00000000,
	0b00011110,
	0b00100010,
	0b00100000,
	0b00100000,
	0b11111100,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b11111000,
	0b00000000,
	0b00000000,
	//g
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000010,
	0b00111100,
	0b01000010,
	0b01000010,
	0b00111100,
	0b01000000,
	0b00111100,
	0b00000010,
	0b01000010,
	0b00111100,
	//h
	0b00000000,
	0b00000000,
	0b00000000,
	0b11000000,
	0b01000000,
	0b01000000,
	0b01000000,
	0b01011100,
	0b01100010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,

	//i
	0b00000000,
	0b00000000,
	0b00000000,
	0b00110000,
	0b00110000,
	0b00000000,
	0b00000000,
	0b01110000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b01111100,
	0b00000000,
	0b00000000,
	//j
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//k
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//l
	0b00000000,
	0b00000000,
	0b00000000,
	0b01110000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b01111100,
	0b00000000,
	0b00000000,
	//m
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11111110,
	0b01001001,
	0b01001001,
	0b01001001,
	0b01001001,
	0b01001001,
	0b11101101,
	0b00000000,
	0b00000000,
	//n
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11011100,
	0b01100010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b11100111,
	0b00000000,
	0b00000000,
	//o
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b00111100,
	0b00000000,
	0b00000000,
	//p
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11011000,
	0b01100100,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000100,
	0b01111000,
	0b01000000,
	0b11100000,
	//q
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//r
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11101110,
	0b00110010,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b11111000,
	0b00000000,
	0b00000000,
	//s
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00111110,
	0b01000010,
	0b01000000,
	0b00111100,
	0b00000010,
	0b01000010,
	0b01111100,
	0b00000000,
	0b00000000,
	//t
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00010000,
	0b00010000,
	0b01111100,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00001100,
	0b00000000,
	0b00000000,
	//u
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11000110,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000010,
	0b01000110,
	0b00111011,
	0b00000000,
	0b00000000,
	//v
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11101110,
	0b01000100,
	0b01000100,
	0b00101000,
	0b00101000,
	0b00010000,
	0b00010000,
	0b00000000,
	0b00000000,
	//w
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11010111,
	0b10010010,
	0b10010010,
	0b10101010,
	0b10101010,
	0b01000100,
	0b01000100,
	0b00000000,
	0b00000000,
	//x
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01101110,
	0b00100100,
	0b00011000,
	0b00011000,
	0b00011000,
	0b00100100,
	0b01110110,
	0b00000000,
	0b00000000,
	//y
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b11100111,
	0b01000010,
	0b00100100,
	0b00100100,
	0b00101000,
	0b00011000,
	0b00010000,
	0b00010000,
	0b11100000,
	//z
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b01111110,
	0b01000100,
	0b00001000,
	0b00010000,
	0b00010000,
	0b00100010,
	0b01111110,
	0b00000000,
	0b00000000,
	/* 123 0x7b '{' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 124 0x7c '|' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 125 0x7d '}' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 126 0x7e '~' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111,
	/* 127 0x7f '' */
	0b11111111,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b10000001,	0b11111111
};

void gui_register_font_simsun()
{
	gui_font_t font;
	
    memset(font.name, 0, GUI_FONT_NAME_LEN);
	strcpy(font.name, FONT_NAME);
    
    memset(font.copyright, 0, GUI_FONT_COPYRIGHT_NAME_LEN);
	strcpy(font.copyright, FONT_COPYRIGHT);
	
	font.addr = font_data_simsun;
	font.width = 8;
	font.height = 16;
	if(gui_register_font(&font) == -1){
		printf("[font] register font %s %s faild!\n", FONT_NAME, FONT_COPYRIGHT);
	}
}
#endif /* CONFIG_FONT_SIMSUN */