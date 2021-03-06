
#include "oclr_global.h"

#define OCLRASTER_IMAGE_UCHAR4
#include "oclr_image.h"

//

#define FXAA_GATHER4_ALPHA 0

/*============================================================================
 
 
 NVIDIA FXAA 3.11 by TIMOTHY LOTTES
 
 
 ------------------------------------------------------------------------------
 COPYRIGHT (C) 2010, 2011 NVIDIA CORPORATION. ALL RIGHTS RESERVED.
 ------------------------------------------------------------------------------
 TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
 *AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
 OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL NVIDIA
 OR ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR
 CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
 LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
 OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE
 THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 DAMAGES.
*/

/*============================================================================
 
 INTEGRATION KNOBS
 
 ============================================================================*/

/*==========================================================================*/
#ifndef FXAA_GREEN_AS_LUMA
//
// For those using non-linear color,
// and either not able to get luma in alpha, or not wanting to,
// this enables FXAA to run using green as a proxy for luma.
// So with this enabled, no need to pack luma in alpha.
//
// This will turn off AA on anything which lacks some amount of green.
// Pure red and blue or combination of only R and B, will get no AA.
//
// Might want to lower the settings for both,
//    fxaaConsoleEdgeThresholdMin
//    fxaaQualityEdgeThresholdMin
// In order to insure AA does not get turned off on colors
// which contain a minor amount of green.
//
// 1 = On.
// 0 = Off.
//
#define FXAA_GREEN_AS_LUMA 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef FXAA_DISCARD
//
// Only valid for PC OpenGL currently.
// Probably will not work when FXAA_GREEN_AS_LUMA = 1.
//
// 1 = Use discard on pixels which don't need AA.
//     For APIs which enable concurrent TEX+ROP from same surface.
// 0 = Return unchanged color on pixels which don't need AA.
//
#define FXAA_DISCARD 0
#endif

/*============================================================================
 FXAA QUALITY - TUNING KNOBS
 ------------------------------------------------------------------------------
 NOTE the other tuning knobs are now in the shader function inputs!
 ============================================================================*/
#ifndef FXAA_QUALITY__PRESET
//
// Choose the quality preset.
// This needs to be compiled into the shader as it effects code.
// Best option to include multiple presets is to
// in each shader define the preset, then include this file.
//
// OPTIONS
// -----------------------------------------------------------------------
// 10 to 15 - default medium dither (10=fastest, 15=highest quality)
// 20 to 29 - less dither, more expensive (20=fastest, 29=highest quality)
// 39       - no dither, very expensive
//
// NOTES
// -----------------------------------------------------------------------
// 12 = slightly faster then FXAA 3.9 and higher edge quality (default)
// 13 = about same speed as FXAA 3.9 and better than 12
// 23 = closest to FXAA 3.9 visually and performance wise
//  _ = the lowest digit is directly related to performance
// _  = the highest digit is directly related to style
//
#define FXAA_QUALITY__PRESET 29
//#define FXAA_QUALITY__PRESET 12
#endif


/*============================================================================
 
 FXAA QUALITY - PRESETS
 
 ============================================================================*/

/*============================================================================
 FXAA QUALITY - MEDIUM DITHER PRESETS
 ============================================================================*/
#if (FXAA_QUALITY__PRESET == 10)
#define FXAA_QUALITY__PS 3
#define FXAA_QUALITY__P0 1.5
#define FXAA_QUALITY__P1 3.0
#define FXAA_QUALITY__P2 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 11)
#define FXAA_QUALITY__PS 4
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 3.0
#define FXAA_QUALITY__P3 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 12)
#define FXAA_QUALITY__PS 5
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 4.0
#define FXAA_QUALITY__P4 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 13)
#define FXAA_QUALITY__PS 6
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 4.0
#define FXAA_QUALITY__P5 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 14)
#define FXAA_QUALITY__PS 7
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 4.0
#define FXAA_QUALITY__P6 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 15)
#define FXAA_QUALITY__PS 8
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 4.0
#define FXAA_QUALITY__P7 12.0
#endif

/*============================================================================
 FXAA QUALITY - LOW DITHER PRESETS
 ============================================================================*/
#if (FXAA_QUALITY__PRESET == 20)
#define FXAA_QUALITY__PS 3
#define FXAA_QUALITY__P0 1.5
#define FXAA_QUALITY__P1 2.0
#define FXAA_QUALITY__P2 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 21)
#define FXAA_QUALITY__PS 4
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 22)
#define FXAA_QUALITY__PS 5
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 23)
#define FXAA_QUALITY__PS 6
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 24)
#define FXAA_QUALITY__PS 7
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 3.0
#define FXAA_QUALITY__P6 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 25)
#define FXAA_QUALITY__PS 8
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 4.0
#define FXAA_QUALITY__P7 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 26)
#define FXAA_QUALITY__PS 9
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 2.0
#define FXAA_QUALITY__P7 4.0
#define FXAA_QUALITY__P8 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 27)
#define FXAA_QUALITY__PS 10
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 2.0
#define FXAA_QUALITY__P7 2.0
#define FXAA_QUALITY__P8 4.0
#define FXAA_QUALITY__P9 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 28)
#define FXAA_QUALITY__PS 11
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 2.0
#define FXAA_QUALITY__P7 2.0
#define FXAA_QUALITY__P8 2.0
#define FXAA_QUALITY__P9 4.0
#define FXAA_QUALITY__P10 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PRESET == 29)
#define FXAA_QUALITY__PS 12
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.5
#define FXAA_QUALITY__P2 2.0
#define FXAA_QUALITY__P3 2.0
#define FXAA_QUALITY__P4 2.0
#define FXAA_QUALITY__P5 2.0
#define FXAA_QUALITY__P6 2.0
#define FXAA_QUALITY__P7 2.0
#define FXAA_QUALITY__P8 2.0
#define FXAA_QUALITY__P9 2.0
#define FXAA_QUALITY__P10 4.0
#define FXAA_QUALITY__P11 8.0
#endif

/*============================================================================
 FXAA QUALITY - EXTREME QUALITY
 ============================================================================*/
#if (FXAA_QUALITY__PRESET == 39)
#define FXAA_QUALITY__PS 12
#define FXAA_QUALITY__P0 1.0
#define FXAA_QUALITY__P1 1.0
#define FXAA_QUALITY__P2 1.0
#define FXAA_QUALITY__P3 1.0
#define FXAA_QUALITY__P4 1.0
#define FXAA_QUALITY__P5 1.5
#define FXAA_QUALITY__P6 2.0
#define FXAA_QUALITY__P7 2.0
#define FXAA_QUALITY__P8 2.0
#define FXAA_QUALITY__P9 2.0
#define FXAA_QUALITY__P10 4.0
#define FXAA_QUALITY__P11 8.0
#endif



/*============================================================================
 
 API PORTING
 
 ============================================================================*/

#define FxaaBool bool
#define FxaaDiscard discard
#define FxaaFloat float
#define FxaaFloat2 float2
#define FxaaFloat3 float3
#define FxaaFloat4 float4
#define FxaaHalf float
#define FxaaHalf2 float2
#define FxaaHalf3 float3
#define FxaaHalf4 float4
#define FxaaInt2 (int2)
#define FxaaSat(x) clamp(x, 0.0f, 1.0f)
#define FxaaTex global uchar4*

/*--------------------------------------------------------------------------*/

// Requires "#version 130" or better
//#define FxaaTexTop(t, p) textureLod(t, p, 0.0)
//#define FxaaTexOff(t, p, o, r) textureLodOffset(t, p, 0.0, o)

#define FxaaTexTop(t, p) image_read(t, linear_sampler, p)
#define FxaaTexOff(t, p, o, r) image_read(t, linear_sampler, p + o)

//#if (FXAA_GATHER4_ALPHA == 1)
// use #extension GL_ARB_gpu_shader5 : enable
//#define FxaaTexAlpha4(t, p) textureGather(t, p, 3)
//#define FxaaTexOffAlpha4(t, p, o) textureGatherOffset(t, p, o, 3)
//#define FxaaTexGreen4(t, p) textureGather(t, p, 1)
//#define FxaaTexOffGreen4(t, p, o) textureGatherOffset(t, p, o, 1)
//#endif


/*============================================================================
 GREEN AS LUMA OPTION SUPPORT FUNCTION
 ============================================================================*/
#if (FXAA_GREEN_AS_LUMA == 0)
FxaaFloat FxaaLuma(FxaaFloat4 rgba) { return rgba.w; }
#else
FxaaFloat FxaaLuma(FxaaFloat4 rgba) { return rgba.y; }
#endif


/*============================================================================
 
 FXAA3 QUALITY - PC
 
 ============================================================================*/
/*--------------------------------------------------------------------------*/
FxaaFloat4 FxaaPixelShader(
						   //
						   // Use noperspective interpolation here (turn off perspective interpolation).
						   // {xy} = center of pixel
						   FxaaFloat2 pos,
						   //
						   // Input color texture.
						   // {rgb_} = color in linear or perceptual color space
						   // if (FXAA_GREEN_AS_LUMA == 0)
						   //     {___a} = luma in perceptual color space (not linear)
						   FxaaTex tex,
						   //
						   // Only used on FXAA Quality.
						   // This must be from a constant/uniform.
						   // {x_} = 1.0/screenWidthInPixels
						   // {_y} = 1.0/screenHeightInPixels
						   FxaaFloat2 fxaaQualityRcpFrame,
						   //
						   // Only used on FXAA Quality.
						   // This used to be the FXAA_QUALITY__SUBPIX define.
						   // It is here now to allow easier tuning.
						   // Choose the amount of sub-pixel aliasing removal.
						   // This can effect sharpness.
						   //   1.00 - upper limit (softer)
						   //   0.75 - default amount of filtering
						   //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
						   //   0.25 - almost off
						   //   0.00 - completely off
						   FxaaFloat fxaaQualitySubpix,
						   //
						   // Only used on FXAA Quality.
						   // This used to be the FXAA_QUALITY__EDGE_THRESHOLD define.
						   // It is here now to allow easier tuning.
						   // The minimum amount of local contrast required to apply algorithm.
						   //   0.333 - too little (faster)
						   //   0.250 - low quality
						   //   0.166 - default
						   //   0.125 - high quality
						   //   0.063 - overkill (slower)
						   FxaaFloat fxaaQualityEdgeThreshold,
						   //
						   // Only used on FXAA Quality.
						   // This used to be the FXAA_QUALITY__EDGE_THRESHOLD_MIN define.
						   // It is here now to allow easier tuning.
						   // Trims the algorithm from processing darks.
						   //   0.0833 - upper limit (default, the start of visible unfiltered edges)
						   //   0.0625 - high quality (faster)
						   //   0.0312 - visible limit (slower)
						   // Special notes when using FXAA_GREEN_AS_LUMA,
						   //   Likely want to set this to zero.
						   //   As colors that are mostly not-green
						   //   will appear very dark in the green channel!
						   //   Tune by looking at mostly non-green content,
						   //   then start at zero and increase until aliasing is a problem.
						   FxaaFloat fxaaQualityEdgeThresholdMin
						   ) {
	/*--------------------------------------------------------------------------*/
	const oclr_sampler_t point_sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;
	const oclr_sampler_t linear_sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_LINEAR;
    FxaaFloat2 posM;
    posM.x = pos.x;
    posM.y = pos.y;
#if (FXAA_GATHER4_ALPHA == 1)
#if (FXAA_DISCARD == 0)
	FxaaFloat4 rgbyM = FxaaTexTop(tex, posM);
#if (FXAA_GREEN_AS_LUMA == 0)
#define lumaM rgbyM.w
#else
#define lumaM rgbyM.y
#endif
#endif
#if (FXAA_GREEN_AS_LUMA == 0)
	FxaaFloat4 luma4A = FxaaTexAlpha4(tex, posM);
	FxaaFloat4 luma4B = FxaaTexOffAlpha4(tex, posM, FxaaInt2(-1, -1));
#else
	FxaaFloat4 luma4A = FxaaTexGreen4(tex, posM);
	FxaaFloat4 luma4B = FxaaTexOffGreen4(tex, posM, FxaaInt2(-1, -1));
#endif
#if (FXAA_DISCARD == 1)
#define lumaM luma4A.w
#endif
#define lumaE luma4A.z
#define lumaS luma4A.x
#define lumaSE luma4A.y
#define lumaNW luma4B.w
#define lumaN luma4B.z
#define lumaW luma4B.x
#else
	FxaaFloat4 rgbyM = FxaaTexTop(tex, posM);
#if (FXAA_GREEN_AS_LUMA == 0)
#define lumaM rgbyM.w
#else
#define lumaM rgbyM.y
#endif
	FxaaFloat lumaS = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2( 0, 1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaE = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2( 1, 0), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaN = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2( 0,-1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaW = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2(-1, 0), fxaaQualityRcpFrame.xy));
#endif
	/*--------------------------------------------------------------------------*/
    FxaaFloat maxSM = max(lumaS, lumaM);
    FxaaFloat minSM = min(lumaS, lumaM);
    FxaaFloat maxESM = max(lumaE, maxSM);
    FxaaFloat minESM = min(lumaE, minSM);
    FxaaFloat maxWN = max(lumaN, lumaW);
    FxaaFloat minWN = min(lumaN, lumaW);
    FxaaFloat rangeMax = max(maxWN, maxESM);
    FxaaFloat rangeMin = min(minWN, minESM);
    FxaaFloat rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
    FxaaFloat range = rangeMax - rangeMin;
    FxaaFloat rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
    FxaaBool earlyExit = range < rangeMaxClamped;
	/*--------------------------------------------------------------------------*/
    if(earlyExit)
#if (FXAA_DISCARD == 1)
		FxaaDiscard;
#else
	return rgbyM;
#endif
	/*--------------------------------------------------------------------------*/
#if (FXAA_GATHER4_ALPHA == 0)
	FxaaFloat lumaNW = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2(-1,-1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaSE = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2( 1, 1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaNE = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2( 1,-1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaSW = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2(-1, 1), fxaaQualityRcpFrame.xy));
#else
	FxaaFloat lumaNE = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2(1, -1), fxaaQualityRcpFrame.xy));
	FxaaFloat lumaSW = FxaaLuma(FxaaTexOff(tex, posM, FxaaInt2(-1, 1), fxaaQualityRcpFrame.xy));
#endif
	/*--------------------------------------------------------------------------*/
    FxaaFloat lumaNS = lumaN + lumaS;
    FxaaFloat lumaWE = lumaW + lumaE;
    FxaaFloat subpixRcpRange = 1.0/range;
    FxaaFloat subpixNSWE = lumaNS + lumaWE;
    FxaaFloat edgeHorz1 = (-2.0 * lumaM) + lumaNS;
    FxaaFloat edgeVert1 = (-2.0 * lumaM) + lumaWE;
	/*--------------------------------------------------------------------------*/
    FxaaFloat lumaNESE = lumaNE + lumaSE;
    FxaaFloat lumaNWNE = lumaNW + lumaNE;
    FxaaFloat edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
    FxaaFloat edgeVert2 = (-2.0 * lumaN) + lumaNWNE;
	/*--------------------------------------------------------------------------*/
    FxaaFloat lumaNWSW = lumaNW + lumaSW;
    FxaaFloat lumaSWSE = lumaSW + lumaSE;
    FxaaFloat edgeHorz4 = (fabs(edgeHorz1) * 2.0) + fabs(edgeHorz2);
    FxaaFloat edgeVert4 = (fabs(edgeVert1) * 2.0) + fabs(edgeVert2);
    FxaaFloat edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
    FxaaFloat edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
    FxaaFloat edgeHorz = fabs(edgeHorz3) + edgeHorz4;
    FxaaFloat edgeVert = fabs(edgeVert3) + edgeVert4;
	/*--------------------------------------------------------------------------*/
    FxaaFloat subpixNWSWNESE = lumaNWSW + lumaNESE;
    FxaaFloat lengthSign = fxaaQualityRcpFrame.x;
    FxaaBool horzSpan = edgeHorz >= edgeVert;
    FxaaFloat subpixA = subpixNSWE * 2.0 + subpixNWSWNESE;
	/*--------------------------------------------------------------------------*/
    if(!horzSpan) lumaN = lumaW;
    if(!horzSpan) lumaS = lumaE;
    if(horzSpan) lengthSign = fxaaQualityRcpFrame.y;
    FxaaFloat subpixB = (subpixA * (1.0/12.0)) - lumaM;
	/*--------------------------------------------------------------------------*/
    FxaaFloat gradientN = lumaN - lumaM;
    FxaaFloat gradientS = lumaS - lumaM;
    FxaaFloat lumaNN = lumaN + lumaM;
    FxaaFloat lumaSS = lumaS + lumaM;
    FxaaBool pairN = fabs(gradientN) >= fabs(gradientS);
    FxaaFloat gradient = max(fabs(gradientN), fabs(gradientS));
    if(pairN) lengthSign = -lengthSign;
    FxaaFloat subpixC = FxaaSat(fabs(subpixB) * subpixRcpRange);
	/*--------------------------------------------------------------------------*/
    FxaaFloat2 posB;
    posB.x = posM.x;
    posB.y = posM.y;
    FxaaFloat2 offNP;
    offNP.x = (!horzSpan) ? 0.0 : fxaaQualityRcpFrame.x;
    offNP.y = ( horzSpan) ? 0.0 : fxaaQualityRcpFrame.y;
    if(!horzSpan) posB.x += lengthSign * 0.5;
    if( horzSpan) posB.y += lengthSign * 0.5;
	/*--------------------------------------------------------------------------*/
    FxaaFloat2 posN;
    posN.x = posB.x - offNP.x * FXAA_QUALITY__P0;
    posN.y = posB.y - offNP.y * FXAA_QUALITY__P0;
    FxaaFloat2 posP;
    posP.x = posB.x + offNP.x * FXAA_QUALITY__P0;
    posP.y = posB.y + offNP.y * FXAA_QUALITY__P0;
    FxaaFloat subpixD = ((-2.0)*subpixC) + 3.0;
    FxaaFloat lumaEndN = FxaaLuma(FxaaTexTop(tex, posN));
    FxaaFloat subpixE = subpixC * subpixC;
    FxaaFloat lumaEndP = FxaaLuma(FxaaTexTop(tex, posP));
	/*--------------------------------------------------------------------------*/
    if(!pairN) lumaNN = lumaSS;
    FxaaFloat gradientScaled = gradient * 1.0/4.0;
    FxaaFloat lumaMM = lumaM - lumaNN * 0.5;
    FxaaFloat subpixF = subpixD * subpixE;
    FxaaBool lumaMLTZero = lumaMM < 0.0;
	/*--------------------------------------------------------------------------*/
    lumaEndN -= lumaNN * 0.5;
    lumaEndP -= lumaNN * 0.5;
    FxaaBool doneN = fabs(lumaEndN) >= gradientScaled;
    FxaaBool doneP = fabs(lumaEndP) >= gradientScaled;
    if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P1;
    if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P1;
    FxaaBool doneNP = (!doneN) || (!doneP);
    if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P1;
    if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P1;
	/*--------------------------------------------------------------------------*/
    if(doneNP) {
        if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
        if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = fabs(lumaEndN) >= gradientScaled;
        doneP = fabs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P2;
        if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P2;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P2;
        if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P2;
		/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 3)
        if(doneNP) {
            if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
            if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = fabs(lumaEndN) >= gradientScaled;
            doneP = fabs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P3;
            if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P3;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P3;
            if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P3;
			/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 4)
            if(doneNP) {
                if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
                if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = fabs(lumaEndN) >= gradientScaled;
                doneP = fabs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P4;
                if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P4;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P4;
                if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P4;
				/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 5)
                if(doneNP) {
                    if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
                    if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = fabs(lumaEndN) >= gradientScaled;
                    doneP = fabs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P5;
                    if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P5;
                    doneNP = (!doneN) || (!doneP);
                    if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P5;
                    if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P5;
					/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 6)
                    if(doneNP) {
                        if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
                        if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
                        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                        doneN = fabs(lumaEndN) >= gradientScaled;
                        doneP = fabs(lumaEndP) >= gradientScaled;
                        if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P6;
                        if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P6;
                        doneNP = (!doneN) || (!doneP);
                        if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P6;
                        if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P6;
						/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 7)
                        if(doneNP) {
                            if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
                            if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
                            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                            doneN = fabs(lumaEndN) >= gradientScaled;
                            doneP = fabs(lumaEndP) >= gradientScaled;
                            if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P7;
                            if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P7;
                            doneNP = (!doneN) || (!doneP);
                            if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P7;
                            if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P7;
							/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 8)
							if(doneNP) {
								if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
								if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
								if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
								if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
								doneN = fabs(lumaEndN) >= gradientScaled;
								doneP = fabs(lumaEndP) >= gradientScaled;
								if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P8;
								if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P8;
								doneNP = (!doneN) || (!doneP);
								if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P8;
								if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P8;
								/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 9)
								if(doneNP) {
									if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
									if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
									if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
									if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
									doneN = fabs(lumaEndN) >= gradientScaled;
									doneP = fabs(lumaEndP) >= gradientScaled;
									if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P9;
									if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P9;
									doneNP = (!doneN) || (!doneP);
									if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P9;
									if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P9;
									/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 10)
									if(doneNP) {
										if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
										if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
										if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
										if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
										doneN = fabs(lumaEndN) >= gradientScaled;
										doneP = fabs(lumaEndP) >= gradientScaled;
										if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P10;
										if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P10;
										doneNP = (!doneN) || (!doneP);
										if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P10;
										if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P10;
										/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 11)
										if(doneNP) {
											if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
											if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
											if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
											if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
											doneN = fabs(lumaEndN) >= gradientScaled;
											doneP = fabs(lumaEndP) >= gradientScaled;
											if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P11;
											if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P11;
											doneNP = (!doneN) || (!doneP);
											if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P11;
											if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P11;
											/*--------------------------------------------------------------------------*/
#if (FXAA_QUALITY__PS > 12)
											if(doneNP) {
												if(!doneN) lumaEndN = FxaaLuma(FxaaTexTop(tex, posN.xy));
												if(!doneP) lumaEndP = FxaaLuma(FxaaTexTop(tex, posP.xy));
												if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
												if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
												doneN = fabs(lumaEndN) >= gradientScaled;
												doneP = fabs(lumaEndP) >= gradientScaled;
												if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P12;
												if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P12;
												doneNP = (!doneN) || (!doneP);
												if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P12;
												if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P12;
												/*--------------------------------------------------------------------------*/
											}
#endif
											/*--------------------------------------------------------------------------*/
										}
#endif
										/*--------------------------------------------------------------------------*/
									}
#endif
									/*--------------------------------------------------------------------------*/
								}
#endif
								/*--------------------------------------------------------------------------*/
							}
#endif
							/*--------------------------------------------------------------------------*/
                        }
#endif
						/*--------------------------------------------------------------------------*/
                    }
#endif
					/*--------------------------------------------------------------------------*/
                }
#endif
				/*--------------------------------------------------------------------------*/
            }
#endif
			/*--------------------------------------------------------------------------*/
        }
#endif
		/*--------------------------------------------------------------------------*/
    }
	/*--------------------------------------------------------------------------*/
    FxaaFloat dstN = posM.x - posN.x;
    FxaaFloat dstP = posP.x - posM.x;
    if(!horzSpan) dstN = posM.y - posN.y;
    if(!horzSpan) dstP = posP.y - posM.y;
	/*--------------------------------------------------------------------------*/
    FxaaBool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
    FxaaFloat spanLength = (dstP + dstN);
    FxaaBool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
    FxaaFloat spanLengthRcp = 1.0/spanLength;
	/*--------------------------------------------------------------------------*/
    FxaaBool directionN = dstN < dstP;
    FxaaFloat dst = min(dstN, dstP);
    FxaaBool goodSpan = directionN ? goodSpanN : goodSpanP;
    FxaaFloat subpixG = subpixF * subpixF;
    FxaaFloat pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
    FxaaFloat subpixH = subpixG * fxaaQualitySubpix;
	/*--------------------------------------------------------------------------*/
    FxaaFloat pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
    FxaaFloat pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
    if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
    if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;
#if (FXAA_DISCARD == 1)
	return FxaaTexTop(tex, posM);
#else
	return (FxaaFloat4)(FxaaTexTop(tex, posM).xyz, lumaM);
#endif
}
/*==========================================================================*/

//
kernel void framebuffer_fxaa(//###OCLRASTER_FRAMEBUFFER_IMAGES###
							 global uchar4* framebuffer,
							 const uint2 framebuffer_size) {
	const unsigned int x = get_global_id(0);
	const unsigned int y = get_global_id(1);
	if(x >= framebuffer_size.x || y >= framebuffer_size.y) {
		return;
	}
	const float2 framebuffer_size_float = convert_float2(framebuffer_size);
	const float2 texel_size = (float2)(1.0f, 1.0f) / framebuffer_size_float;
	const float2 tex_coord = (float2)(0.5f + (float)x, 0.5f + (float)y) / framebuffer_size_float;
	//const float2 tex_coord = (float2)((float)x, (float)y) / framebuffer_size_float;
	//if(y == 300) printf("tex coord: %f %f\n", tex_coord.x, tex_coord.y);
	
	//
	const float4 color = FxaaPixelShader(// Use noperspective interpolation here (turn off perspective interpolation).
										 // {xy} = center of pixel
										 tex_coord,
										 //
										 // Input color texture.
										 // {rgb_} = color in linear or perceptual color space
										 // if (FXAA_GREEN_AS_LUMA == 0)
										 //     {___a} = luma in perceptual color space (not linear)
										 framebuffer,
										 //
										 // Only used on FXAA Quality.
										 // This must be from a constant/uniform.
										 // {x_} = 1.0/screenWidthInPixels
										 // {_y} = 1.0/screenHeightInPixels
										 texel_size,
										 //
										 // Only used on FXAA Quality.
										 // This used to be the FXAA_QUALITY__SUBPIX define.
										 // It is here now to allow easier tuning.
										 // Choose the amount of sub-pixel aliasing removal.
										 // This can effect sharpness.
										 //   1.00 - upper limit (softer)
										 //   0.75 - default amount of filtering
										 //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
										 //   0.25 - almost off
										 //   0.00 - completely off
										 0.75f,
										 //
										 // Only used on FXAA Quality.
										 // This used to be the FXAA_QUALITY__EDGE_THRESHOLD define.
										 // It is here now to allow easier tuning.
										 // The minimum amount of local contrast required to apply algorithm.
										 //   0.333 - too little (faster)
										 //   0.250 - low quality
										 //   0.166 - default
										 //   0.125 - high quality
										 //   0.063 - overkill (slower)
										 0.125f,
										 //
										 // Only used on FXAA Quality.
										 // This used to be the FXAA_QUALITY__EDGE_THRESHOLD_MIN define.
										 // It is here now to allow easier tuning.
										 // Trims the algorithm from processing darks.
										 //   0.0833 - upper limit (default, the start of visible unfiltered edges)
										 //   0.0625 - high quality (faster)
										 //   0.0312 - visible limit (slower)
										 // Special notes when using FXAA_GREEN_AS_LUMA,
										 //   Likely want to set this to zero.
										 //   As colors that are mostly not-green
										 //   will appear very dark in the green channel!
										 //   Tune by looking at mostly non-green content,
										 //   then start at zero and increase until aliasing is a problem.
										 0.0833f);
	//const oclr_sampler_t point_sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;
	//const float luma = image_read(framebuffer, point_sampler, (uint2)(x, y)).w;
	//image_write(framebuffer, (uint2)(x, y), (float4)(luma, luma, luma, 1.0f));
	image_write(framebuffer, (uint2)(x, y), (float4)(color.xyz, 1.0f));
}
