/* stb_image - v2.26 - public domain image loader - http://nothings.org/stb
                                  no warranty implied; use at your own risk
   Do this:
      using STB-Beef;
    This will take care of everything for you. :)
   QUICK NOTES:
      Primarily of interest to game developers and other people who can avoid problematic images and only need the trivial interface
      JPEG baseline & progressive (12 bpc/arithmetic not supported, same as stock IJG lib)
      PNG 1/2/4/8/16-bit-per-channel
      TGA (not sure what subset, if a subset)
      BMP non-1bpp, non-RLE
      PSD (composited view only, no extra channels, 8/16 bit-per-channel)
      GIF (*comp always reports as 4-channel)
      HDR (radiance rgbE format)
      PIC (Softimage PIC)
      PNM (PPM and PGM binary only)
      Animated GIF still needs a proper API, but here's one way to do it: http://gist.github.com/urraka/685d9a6340b26b830d49
      - decode from memory or through FILE (define STBI_NO_STDIO to remove code)
      - decode from arbitrary I/O callbacks
      - SIMD acceleration on x86/x64 (SSE2) and ARM (NEON)
   Full documentation under "DOCUMENTATION" below.
LICENSE
  See end of file for license information.
RECENT REVISION HISTORY:
      2.26  (2020-07-13) many minor fixes
      2.25  (2020-02-02) fix warnings
      2.24  (2020-02-02) fix warnings; thread-local failure_reason and flip_vertically
      2.23  (2019-08-11) fix clang static analysis warning
      2.22  (2019-03-04) gif fixes, fix warnings
      2.21  (2019-02-25) fix typo in comment
      2.20  (2019-02-07) support utf8 filenames in Windows; fix warnings and platform ifdefs
      2.19  (2018-02-11) fix warning
      2.18  (2018-01-30) fix warnings
      2.17  (2018-01-29) bugfix, 1-bit BMP, 16-bitness query, fix warnings
      2.16  (2017-07-23) all functions have 16-bit variants; optimizations; bugfixes
      2.15  (2017-03-18) fix png-1,2,4; all Imagenet JPGs; no runtime SSE detection on GCC
      2.14  (2017-03-03) remove deprecated STBI_JPEG_OLD; fixes for Imagenet JPGs
      2.13  (2016-12-04) experimental 16-bit API, only for PNG so far; fixes
      2.12  (2016-04-02) fix typo in 2.11 PSD fix that caused crashes
      2.11  (2016-04-02) 16-bit PNGS; enable SSE2 in non-gcc x64
                         RGB-format JPEG; remove white matting in PSD;
                         allocate large structures on the stack;
                         correct channel count for PNG & BMP
      2.10  (2016-01-22) avoid warning introduced in 2.09
      2.09  (2016-01-16) 16-bit TGA; comments in PNM files; STBI_REALLOC_SIZED
   See end of file for full revision history.
 ============================    Contributors    =========================
 Image formats                          Extensions, features
    Sean Barrett (jpeg, png, bmp)          Jetro Lauha (stbi_info)
    Nicolas Schulz (hdr, psd)              Martin "SpartanJ" Golini (stbi_info)
    Jonathan Dummer (tga)                  James "moose2000" Brown (iPhone PNG)
    Jean-Marc Lienher (gif)                Ben "Disch" Wenger (io callbacks)
    Tom Seddon (pic)                       Omar Cornut (1/2/4-bit PNG)
    Thatcher Ulrich (psd)                  Nicolas Guillemot (vertical flip)
    Ken Miller (pgm, ppm)                  Richard Mitton (16-bit PSD)
    github:urraka (animated gif)           Junggon Kim (PNM comments)
    Christopher Forseth (animated gif)     Daniel Gibson (16-bit TGA)
                                           socks-the-fox (16-bit PNG)
                                           Jeremy Sawicki (handle all ImageNet JPGs)
 Optimizations & bugfixes                  Mikhail Morozov (1-bit BMP)
    Fabian "ryg" Giesen                    Anael Seghezzi (is-16-bit query)
    Arseny Kapoulkine
    John-Mark Allen
    Carmelo J Fdez-Aguera
 Bug & warning fixes
    Marc LeBlanc            David Woo          Guillaume George     Martins Mozeiko
    Christpher Lloyd        Jerry Jansson      Joseph Thomson       Blazej Dariusz Roszkowski
    Phil Jordan                                Dave Moore           Roy Eltham
    Hayaki Saito            Nathan Reed        Won Chun
    Luke Graham             Johan Duparc       Nick Verigakis       the Horde3D community
    Thomas Ruf              Ronny Chevalier                         github:rlyeh
    Janez Zemva             John Bartholomew   Michal Cichon        github:romigrou
    Jonathan Blow           Ken Hamada         Tero Hanninen        github:svdijk
                            Laurent Gomila     Cort Stratton        github:snagar
    Aruelien Pocheville     Sergio Gonzalez    Thibault Reuille     github:Zelex
    Cass Everitt            Ryamond Barbiero                        github:grim210
    Paul Du Bois            Engin Manap        Aldo Culquicondor    github:sammyhw
    Philipp Wiesemann       Dale Weiler        Oriol Ferrer Mesia   github:phprus
    Josh Tobin                                 Matthew Gregan       github:poppolopoppo
    Julian Raschke          Gregory Mullen     Christian Floisand   github:darealshinji
    Baldur Karlsson         Kevin Schmidt      JR Smith             github:Michaelangel007
                            Brad Weinberger    Matvey Cherevko      [reserved]
    Luca Sas                Alexander Veselov  Zack Middleton       [reserved]
    Ryan C. Gordon          [reserved]                              [reserved]
                     DO NOT ADD YOUR NAME HERE
  To add your name to the credits, pick a random blank space in the middle and fill it.
  80% of merge conflicts on stb PRs are due to people adding their name at the end of the credits.

  https://github.com/nothings/stb/blob/master/stb_image.h  
*/

using System;
using System.Diagnostics;
using System.IO;

#if STBI_ONLY_JPEG || STBI_ONLY_PNG || STBI_ONLY_BMP || STBI_ONLY_TGA || STBI_ONLY_GIF || STBI_ONLY_PSD || STBI_ONLY_HDR || STBI_ONLY_PIC || STBI_ONLY_PNM || STBI_ONLY_ZLIB
	#if !STBI_ONLY_JPEG
		#define STBI_NO_JPEG
	#endif
	#if !STBI_ONLY_PNG
		#define STBI_NO_PNG
	#endif
	#if !STBI_ONLY_BMP
		#define STBI_NO_BMP
	#endif
	#if !STBI_ONLY_PSD
		#define STBI_NO_PSD
	#endif
	#if !STBI_ONLY_TGA
		#define STBI_NO_TGA
	#endif
	#if !STBI_ONLY_GIF
		#define STBI_NO_GIF
	#endif
	#if !STBI_ONLY_HDR
		#define STBI_NO_HDR
	#endif
	#if !STBI_ONLY_PIC
		#define STBI_NO_PIC
	#endif
	#if !STBI_ONLY_PNM
		#define STBI_NO_PNM
	#endif
#endif

#if STBI_NO_PNG && !STBI_SUPPORT_ZLIB && !STBI_NO_ZLIB
	#define STBI_NO_ZLIB
#endif

#if BF_64_BIT
	#define STBI__X64_TARGET
#else
	#define STBI__X86_TARGET
#endif

namespace STB_Beef
{
	// DOCUMENTATION
	//
	// Limitations:
	//    - no 12-bit-per-channel JPEG
	//    - no JPEGs with arithmetic coding
	//    - GIF always returns *comp=4
	//
	// Basic usage (see HDR discussion below for HDR usage):
	//    int x, y, n;
	//    uint8* data = STB_Image.Load(filename, out x, out y, out n, 0);
	//    // ... process data if not NULL ...
	//    // ... x = width, y = height, n = # 8-bit components per pixel ...
	//    // ... replace '0' with '1'..'4' to force that many components per pixel
	//    // ... but 'n' will always be the number that it would have been if you said 0
	//    STB_Beef.ImageFree(data)
	//
	// Standard parameters:
	//    out int x                 -- outputs image width in pixels
	//    out int y                 -- outputs image height in pixels
	//    out int channels_in_file  -- outputs # of image components in image file
	//    int desired_channels      -- if non-zero, # of image components requested in result
	//
	// The return value from an image loader is an 'uint8*' which points to the pixel data, or NULL on an allocation failure or if the image is corrupt or invalid. The pixel data consists of *y scanlines of *x pixels,
	// with each pixel consisting of N interleaved 8-bit components; the first pixel pointed to is top-left-most in the image. There is no padding between image scanlines or between pixels, regardless of format. The number of
	// components N is 'desired_channels' if desired_channels is non-zero, or *channels_in_file otherwise. If desired_channels is non-zero, *channels_in_file has the number of components that _would_ have been
	// output otherwise. E.g. if you set desired_channels to 4, you will always get RGBA output, but you can check *channels_in_file to see if it's trivially opaque because e.g. there were only 3 channels in the source image.
	//
	// An output image with N components has the following components interleaved in this order in each pixel:
	//
	//     N=#comp     components
	//       1           grey
	//       2           grey, alpha
	//       3           red, green, blue
	//       4           red, green, blue, alpha
	//
	// If image loading fails for any reason, the return value will be NULL, and *x, *y, *channels_in_file will be unchanged. The function STB_Image.FailureReason() can be queried for an extremely brief, end-user
	// unfriendly explanation of why the load failed. Define STBI_NO_FAILURE_STRINGS to avoid compiling these strings at all, and STBI_FAILURE_USERMSG to get slightly more user-friendly ones.
	//
	// Paletted PNG, BMP, GIF, and PIC images are automatically depalettized.
	//
	// ===========================================================================
	//
	// UNICODE:
	//
	//   If compiling for Windows and you wish to use Unicode filenames, compile with
	//       #define STBI_WINDOWS_UTF8
	//   and pass utf8-encoded filenames. Call STB_Image.ConvertWCharToUtf8 to convert Windows char16 filenames to utf8.
	//
	// ===========================================================================
	//
	// Philosophy
	//
	// stb libraries are designed with the following priorities:
	//
	//    1. easy to use
	//    2. easy to maintain
	//    3. good performance
	//
	// Sometimes I let "good performance" creep up in priority over "easy to maintain", and for best performance I may provide less-easy-to-use APIs that give higher performance, in addition to the easy-to-use ones.
	// Nevertheless, it's important to keep in mind that from the standpoint of you, a client of this library, all you care about is #1 and #3, and stb libraries DO NOT emphasize #3 above all.
	//
	// Some secondary priorities arise directly from the first two, some of which provide more explicit reasons why performance can't be emphasized.
	//
	//    - Portable ("ease of use")
	//    - Small source code footprint ("easy to maintain")
	//    - No dependencies ("ease of use")
	//
	// ===========================================================================
	//
	// I/O callbacks
	//
	// I/O callbacks allow you to read from arbitrary sources, like packaged files or some other source. Data read from callbacks are processed through a small internal buffer (currently 128 bytes) to try to reduce
	// overhead.
	//
	// The three functions you must define are "read" (reads some bytes of data), "skip" (skips some bytes of data), "eof" (reports if the stream is at the end).
	//
	// ===========================================================================
	//
	// SIMD support
	//
	// The JPEG decoder will try to automatically use SIMD kernels on x86 when supported by the compiler. For ARM Neon support, you must explicitly request it.
	//
	// (The old do-it-yourself SIMD API is no longer supported in the current code.)
	//
	// On x86, SSE2 will automatically be used when available based on a run-time test; if not, the generic C versions are used as a fall-back. On ARM targets,
	// the typical path is to have separate builds for NEON and non-NEON devices (at least this is true for iOS and Android). Therefore, the NEON support is toggled by a build flag: define STBI_NEON to get NEON loops.
	//
	// If for some reason you do not want to use any of SIMD code, or if you have issues compiling it, you can disable it entirely by defining STBI_NO_SIMD.
	//
	// ===========================================================================
	//
	// HDR image support   (disable by defining STBI_NO_HDR)
	//
	// stb_image supports loading HDR images in general, and currently the Radiance .HDR file format specifically. You can still load any file through the existing interface;
	// if you attempt to load an HDR file, it will be automatically remapped to LDR, assuming gamma 2.2 and an arbitrary scale factor defaulting to 1;
	// both of these constants can be reconfigured through this interface:
	//
	//     STB_Image.HdrToLdrGamma(2.2f);
	//     STB_Image.HdrToLdrScale(1.0f);
	//
	// (note, do not use _inverse_ constants; stbi_image will invert them appropriately).
	//
	// Additionally, there is a new, parallel interface for loading files as (linear) floats to preserve the full dynamic range:
	//
	//    float* data = STB_Image.LoadF(filename, &x, &y, &n, 0);
	//
	// If you load LDR images through this interface, those images will be promoted to floating point values, run through the inverse of constants corresponding to the above:
	//
	//     STB_Image.LdrToHdrScale(1.0f);
	//     STB_Image.LdrToHdrGamma(2.2f);
	//
	// Finally, given a filename (or an open file or memory block--see header file for details) containing image data, you can query for the "most appropriate" interface to use (that is, whether the image is HDR or
	// not), using:
	//
	//     STB_Image.IsHdr(StringView* filename);
	//
	// ===========================================================================
	//
	// iPhone PNG support:
	//
	// By default we convert iphone-formatted PNGs back to RGB, even though they are internally encoded differently. You can disable this conversion by calling STB_Image.ConvertIPhonePngToRgb(0), in which case
	// you will always just get the native iphone "format" through (which is BGR stored in RGB).
	//
	// Call STB_Image.SetUnpremultiplyOnLoad(1) as well to force a divide per pixel to remove any premultiplied alpha *only* if the image file explicitly says there's premultiplied data (currently only happens in iPhone images,
	// and only if iPhone convert-to-rgb processing is on).
	//
	// ===========================================================================
	//
	// ADDITIONAL CONFIGURATION
	//
	//  - You can suppress implementation of any of the decoders to reduce your code footprint by #defining one or more of the following symbols before creating the implementation.
	//
	//        STBI_NO_JPEG
	//        STBI_NO_PNG
	//        STBI_NO_BMP
	//        STBI_NO_PSD
	//        STBI_NO_TGA
	//        STBI_NO_GIF
	//        STBI_NO_HDR
	//        STBI_NO_PIC
	//        STBI_NO_PNM   (.ppm and .pgm)
	//
	//  - You can request *only* certain decoders and suppress all other ones (this will be more forward-compatible, as addition of new decoders doesn't require you to disable them explicitly):
	//
	//        STBI_ONLY_JPEG
	//        STBI_ONLY_PNG
	//        STBI_ONLY_BMP
	//        STBI_ONLY_PSD
	//        STBI_ONLY_TGA
	//        STBI_ONLY_GIF
	//        STBI_ONLY_HDR
	//        STBI_ONLY_PIC
	//        STBI_ONLY_PNM   (.ppm and .pgm)
	//
	//   - If you use STBI_NO_PNG (or _ONLY_ without PNG), and you still want the zlib decoder to be available, #define STBI_SUPPORT_ZLIB
	//
	//  - If you define STBI_MAX_DIMENSIONS, stb_image will reject images greater than that size (in either width or height) without further processing.
	//    This is to let programs in the wild set an upper bound to prevent denial-of-service attacks on untrusted data, as one could generate a valid image of gigantic dimensions and force STB_Image to allocate a
	//    huge block of memory and spend disproportionate time decoding it. By default this is set to (1 << 24), which is 16777216, but that's still very big.
	class STB_Image
	{
		public const int VERSION = 1;

		public const int STBI_default    = 0; // only used for desired_channels
		public const int STBI_grey       = 1;
		public const int STBI_grey_alpha = 2;
		public const int STBI_rgb        = 3;
		public const int STBI_rgb_alpha  = 4;

		public const int STBI_ORDER_RGB = 0;
		public const int STBI_ORDER_BGR = 1;

		public const int MAX_DIMENSIONS = 1 << 24;

		[ThreadStatic]
		private static String g_failure_reason ~ if (_ != null) delete _;

		// should produce compiler error if size is wrong
		public typealias validate_uint32 = uint8[sizeof(uint32) == 4 ? 1 : -1];

		//////////////////////////////////////////////
		//
		//  Context struct and start_xxx functions

		// Context structure is our basic context used by all images, so it contains all the IO context, plus some basic image information
		private struct Context
		{
			public uint32 img_x;
			public uint32 img_y;
			public int img_n;
			public int img_out_n;

			public io_callbacks io;
			public void* io_user_data;

			public bool read_from_callbacks;
			public int buflen;
			public uint8[128] buffer_start;
			public int callback_already_read;

			public uint8* img_buffer;
			public uint8* img_buffer_end;
			public uint8* img_buffer_original;
			public uint8* img_buffer_original_end;
		}

		private struct ResultInfo
		{
			public int bits_per_channel;
			public int num_channels;
			public int channel_order;
		}

		private static uint32 lrot(uint32 x, uint32 y) => (x << y) | (x >> (32 - y));

		private static void RefillBuffer(ref Context s)
		{
			int n = s.io.read(s.io_user_data, (char8*)&s.buffer_start[0], s.buflen);
			s.callback_already_read += (int)(s.img_buffer - s.img_buffer_original);

			if (n == 0) {
				// at end of file, treat same as if from memory, but need to handle case where s.img_buffer isn't pointing to safe memory, e.g. 0-byte file
				s.read_from_callbacks = 0;
				s.img_buffer = &s.buffer_start[0];
				s.img_buffer_end = &s.buffer_start[0] + 1;
				*s.img_buffer = 0;
			} else {
				s.img_buffer = &s.buffer_start[0];
				s.img_buffer_end = &s.buffer_start[0] + n;
			}
		}

		// initialize a memory-decode context
		private static void StartMem(out Context s, uint8* buffer, int len)
		{
			s = .();
			s.io.read = null;
			s.read_from_callbacks = 0;
			s.callback_already_read = 0;
			s.img_buffer = s.img_buffer_original = (uint8*)buffer;
			s.img_buffer_end = s.img_buffer_original_end = (uint8*)buffer + len;
		}

		// initialize a callback-based context
		private static void StartCallbacks(out Context s, ref io_callbacks c, void* user)
		{
			s = .();
			s.io = c;
			s.io_user_data = user;
			s.buflen = s.buffer_start.Count;
			s.read_from_callbacks = 1;
			s.callback_already_read = 0;
			s.img_buffer = s.img_buffer_original = &s.buffer_start[0];
			RefillBuffer(ref s);
			s.img_buffer_original_end = s.img_buffer_end;
		}

#if !STBI_NO_STDIO
		private static int StdioRead(void* user, char8* data, int size)
		{
			Platform.BfpFileResult fres = .Ok;
			int numBytesRead = Platform.BfpFile_Read((Platform.BfpFile*)user, data, size, -1, &fres);

			if ((fres != .Ok) && (fres != .PartialData))
				return -1;

			return numBytesRead;
		}

		private static void StdioSkip(void* user, int n)
		{
			int ch;
			Platform.BfpFileResult fres = .Ok;
			Platform.BfpFile_Seek((Platform.BfpFile*)user, n, .Relative);
			int len = Platform.BfpFile_Read((Platform.BfpFile*)user, &ch, sizeof(char8), -1, &fres); /* Read one byte to check feof()'s flag */

			if ((len > 0) && ((fres == .Ok) || (fres == .PartialData))) {
				Platform.BfpFile_Seek((Platform.BfpFile*)user, -sizeof(char8), .Relative); /* push byte back onto stream if valid. */
			}
		}

		private static int StdioEof(void* user)
		{
			int ch;
			Platform.BfpFileResult fres = .Ok;
			int len = Platform.BfpFile_Read((Platform.BfpFile*)user, &ch, sizeof(char8), -1, &fres); /* Read one byte to check feof()'s flag */

			if ((len > 0) && ((fres == .Ok) || (fres == .PartialData))) {
				Platform.BfpFile_Seek((Platform.BfpFile*)user, -sizeof(char8), .Relative); /* push byte back onto stream if valid. */
			}

			return fres.Underlying;
		}

		private static io_callbacks stbi__stdio_callbacks = .() {
		   read = => StdioRead,
		   skip = => StdioSkip,
		   eof = => StdioEof
		};

		private static void StartFile(out Context s, Platform.BfpFile* f)
		{
			StartCallbacks(out s, ref stbi__stdio_callbacks, (void*)f);
		}
#endif // !STBI_NO_STDIO

		private static void Rewind(ref Context s)
		{
		   // conceptually rewind SHOULD rewind to the beginning of the stream, but we just rewind to the beginning of the initial buffer, because we only use it after doing 'test', which only ever looks at at most 92 bytes
		   s.img_buffer = s.img_buffer_original;
		   s.img_buffer_end = s.img_buffer_original_end;
		}

		//////////////////////////////////////////////////////////////////////////////
		//
		// PRIMARY API - works on images of any type
		//

		//
		// load image by filename, open file, or memory buffer
		//
		public struct io_callbacks
		{
			public function int(void* user, char8* data, int size) read; // fill 'data' with 'size' bytes.  return number of bytes actually read
			public function void(void* user, int n) skip;                // skip the next 'n' bytes, or 'unget' the last -n bytes if negative
			public function bool(void* user) eof;                        // returns true if we are at end of file/data
		}

		////////////////////////////////////
		//
		// 8-bits-per-channel interface
		//
		public static uint8* LoadFromMemory(uint8* buffer, int len, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartMem(out s, buffer, len);
			return LoadAndPostprocess8bit(ref s, out x, out y, out channels_in_file, desired_channels);
		}

		public static uint8* LoadFromCallbacks(ref io_callbacks clbk, void* user, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartCallbacks(out s, ref clbk, user);
			return LoadAndPostprocess8bit(ref s, out x, out y, out channels_in_file, desired_channels);
		}

#if !STBI_NO_STDIO
		public static uint8* Load(StringView filename, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Platform.BfpFile* f = Fopen(filename, .Open, .Read);
			uint8* result;

			if (f == null) {
				x = y = channels_in_file = 0;
				return Errpuc("can't fopen", "Unable to open file");
			}

			result = LoadFromFile(f, out x, out y, out channels_in_file, desired_channels);
			Platform.BfpFile_Release(f);
			return result;
		}

		public static uint8* LoadFromFile(Platform.BfpFile* f, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			uint8* result;
			Context s;
			StartFile(out s, f);
			result = LoadAndPostprocess8bit(ref s, out x, out y, out channels_in_file, desired_channels);

			if (result != null) // need to 'unget' all the characters in the IO buffer
			   Platform.BfpFile_Seek(f, -(int)(s.img_buffer_end - s.img_buffer), .Relative);

			return result;
		}
		// for LoadFromFile, file pointer is left pointing immediately after image
#endif

#if !STBI_NO_GIF
		public static uint8* LoadGifFromMemory(uint8* buffer, int len, int** delays, out int x, out int y, out int z, out int comp, int req_comp)
		{
			uint8* result;
			Context s;
			StartMem(out s, buffer, len);
			
			result = (uint8*)LoadGifMain(ref s, delays, out x, out y, out z, out comp, req_comp);

			if (VerticallyFlipOnLoad())
			  	VerticalFlipSlices(result, x, y, z, comp);
			
			return result;
		}
#endif

		////////////////////////////////////
		//
		// 16-bits-per-channel interface
		//
		public static uint16* Load16FromMemory(uint8* buffer, int len, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartMem(out s, buffer, len);
			return LoadAndPostprocess16bit(ref s, out x, out y, out channels_in_file, desired_channels);
		}

		public static uint16* Load16FromCallbacks(ref io_callbacks clbk, void* user, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartCallbacks(out s, ref clbk, user);
			return LoadAndPostprocess16bit(ref s, out x, out y, out channels_in_file, desired_channels);
		}

#if !STBI_NO_STDIO
		public static uint16* Load16(StringView filename, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Platform.BfpFile* f = Fopen(filename, .Open, .Read);
			uint16* result;
			
			if (f == null) {
				x = y = channels_in_file = 0;
				return (uint16*)Errpuc("can't fopen", "Unable to open file");
			}
			
			result = LoadFromFile16(f, out x, out y, out channels_in_file, desired_channels);
			Platform.BfpFile_Release(f);
			return result;
		}

		public static uint16* LoadFromFile16(Platform.BfpFile* f, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			uint16* result;
			Context s;
			StartFile(out s, f);
			result = LoadAndPostprocess16bit(ref s, out x, out y, out channels_in_file, desired_channels);

			if (result != null) // need to 'unget' all the characters in the IO buffer
			   Platform.BfpFile_Seek(f, -(int)(s.img_buffer_end - s.img_buffer), .Relative);

			return result;
		}
#endif
		////////////////////////////////////
		//
		// float-per-channel interface
		//
#if !STBI_NO_LINEAR
		private static float* LoadfMain(ref Context s, out int x, out int y, out int comp, int req_comp)
		{
			uint8* data;

	#if !STBI_NO_HDR
			if (HdrTest(ref s)) {
				ResultInfo ri = .();

				float* hdr_data = HdrLoad(ref s, out x, out y, out comp, req_comp, ref ri);

				if (hdr_data != null)
					FloatPostprocess(hdr_data, x, y, comp, req_comp);

				return hdr_data;
			}
	#endif
			data = LoadAndPostprocess8bit(ref s, out x, out y, out comp, req_comp);

			if (data != null)
				return LdrToHdr(data, x, y, req_comp > 0 ? req_comp : comp);

			return Errpf("unknown image type", "Image not of any known type, or corrupt");
		}

		public static float* LoadfFromMemory(uint8* buffer, int len, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartMem(out s, buffer, len);
			return LoadfMain(ref s, out x, out y, out channels_in_file, desired_channels);
		}

		public static float* LoadfFromCallbacks(ref io_callbacks clbk, void* user, out int x, out int y,  out int channels_in_file, int desired_channels)
		{
			Context s;
			StartCallbacks(out s, ref clbk, user);
			return LoadfMain(ref s, out x, out y, out channels_in_file, desired_channels);
		}

	#if !STBI_NO_STDIO
		public static float* Loadf(StringView filename, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			float* result;
			Platform.BfpFile* f = Fopen(filename, .Open, .Read);

			if (f == null) {
				x = y = channels_in_file = 0;
				return Errpf("can't fopen", "Unable to open file");
			}

			result = LoadfFromFile(f, out x, out y, out channels_in_file, desired_channels);
			Platform.BfpFile_Release(f);
			return result;
		}

		public static float* LoadfFromFile(Platform.BfpFile* f, out int x, out int y, out int channels_in_file, int desired_channels)
		{
			Context s;
			StartFile(out s, f);
			return LoadfMain(ref s, out x, out y, out channels_in_file, desired_channels);
		}
	#endif
#endif

#if !STBI_NO_HDR
		private static float H2lGammaI = 1.0f / 2.2f;
		private static float H2lScaleI = 1.0f;

		public static void HdrToLdrGamma(float gamma) { H2lGammaI = 1 / gamma; }

		public static void HdrToLdrScale(float scale) { H2lScaleI = 1 / scale; }
#endif // STBI_NO_HDR

#if !STBI_NO_LINEAR
		private static float L2hGamma = 2.2f;
		private static float L2hScale = 1.0f;

		public static void LdrToHdrGamma(float gamma) { L2hGamma = gamma; }

		public static void LdrToHdrScale(float scale) { L2hScale = scale; }
#endif // STBI_NO_LINEAR

		// IsHdr is always defined, but always returns false if STBI_NO_HDR
		public static bool IsHdrFromCallbacks(ref io_callbacks clbk, void* user)
		{
	#if !STBI_NO_HDR
			Context s;
			StartCallbacks(out s, ref clbk, user);
			return HdrTest(ref s);
	#else
			return false;
	#endif
		}

		public static bool IsHdrFromMemory(uint8* buffer, int len)
		{
	#if !STBI_NO_HDR
			Context s;
			StartMem(out s, buffer, len);
			return HdrTest(ref s);
	#else
			return false;
	#endif
		}

#if !STBI_NO_STDIO
		public static bool IsHdr(StringView filename)
		{
			Platform.BfpFile* f = Fopen(filename, .Open, .Read);
			bool result = false;

			if (f != null) {
			   	result = IsHdrFromFile(f);
				Platform.BfpFile_Release(f);
			}

			return result;
		}

		public static bool IsHdrFromFile(Platform.BfpFile* f)
		{
	#if !STBI_NO_HDR
			int pos = Platform.BfpFile_Seek(f, 0, .Relative); // Seek returns the new pos, so we can use it here to retrieve
			bool res;
			Context s;
			StartFile(out s, f);
			res = HdrTest(ref s);
			Platform.BfpFile_Seek(f, pos, .Absolute);
			return res;
	#else
			return false;
	#endif
		}
#endif // STBI_NO_STDIO

		// get a VERY brief reason for failure on most compilers (and ALL modern mainstream compilers) this is threadsafe
		public static void FailureReason(String outStr)
		{
			outStr.Clear();
			outStr.Append(g_failure_reason);
		}

		// free the loaded image -- this is just free()
		public static void ImageFree(void* retval_from_stbi_load) => Free(retval_from_stbi_load);

		// get image dimensions & components without fully decoding
		public static int InfoFromMemory(uint8* buffer, int len, out int x, out int y, out int comp)
		{

		}

		public static int InfoFromCallbacks(ref io_callbacks clbk, void *user, out int x, out int y, out int comp)
		{

		}

		public static bool Is16BitFromMemory(uint8* buffer, int len)
		{

		}

		public static bool Is16BitFromCallbacks(ref io_callbacks clbk, void* user)
		{

		}


#if !STBI_NO_STDIO
		public static int Info(StringView filename, out int x, out int y, out int comp)
		{

		}

		public static int InfoFromFile(Platform.BfpFile* f, out int x, out int y, out int comp)
		{

		}

		public static bool Is16Bit(StringView filename)
		{

		}

		public static bool Is16BitFromFile(Platform.BfpFile* f)
		{

		}
#endif
		
		// for image formats that explicitly notate that they have premultiplied alpha, we just return the colors as stored in the file. set this flag to force
		// unpremultiplication. results are undefined if the unpremultiply overflow.
		public static void SetUnpremultiplyOnLoad(int flag_true_if_should_unpremultiply)
		{

		}

		// indicate whether we should process iphone images back to canonical format, or just pass them through "as-is"
		public static void ConvertIPhonePngToRgb(int flag_true_if_should_convert)
		{

		}

		// flip the image vertically, so the first pixel in the output array is the bottom left
		public static void SetFlipVerticallyOnLoad(bool flag_true_if_should_flip)
		{
			VerticallyFlipOnLoadGlobal = flag_true_if_should_flip;
		}
		
#if STBI_THREAD_LOCAL
		// as above, but only applies to images loaded on the thread that calls the function this function is only available if your compiler supports thread-local variables; calling it will fail to link if your compiler doesn't
		public static void SetFlipVerticallyOnLoadThread(bool flag_true_if_should_flip)
		{
			VerticallyFlipOnLoadLocal = flag_true_if_should_flip;
			VerticallyFlipOnLoadSet = 1;
		}
#endif

		// ZLIB client - used by PNG, available for other purposes
		public static char8* ZlibDecodeMallocGuesssize(char8* buffer, int len, int initial_size, out int outlen)
		{

		}

		public static char8* ZlibDecodeMallocGuesssizeHeaderflag(char8* buffer, int len, int initial_size, out int outlen, int parse_header)
		{

		}

		public static char8* ZlibDecodeMalloc(char8* buffer, int len, out int outlen)
		{

		}

		public static int ZlibDecodeBuffer(char8* obuffer, int olen, char8* ibuffer, int ilen)
		{

		}

		public static char8* ZlibDecodeNoheaderMalloc(char8* buffer, int len, out int outlen)
		{

		}

		public static int ZlibDecodeNoheaderBuffer(char8* obuffer, int olen, char8* ibuffer, int ilen)
		{

		}

#if !STBI_NO_JPEG
		private static bool JpegTest(ref Context s)
		{

		}

		private static void* JpegLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int JpegInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_PNG
		private static bool PngTest(ref Context s)
		{

		}

		private static void* PngLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int PngInfo(ref Context s, out int x, out int y, out int comp)
		{

		}

		private static int PngIs16(ref Context s)
		{

		}
#endif

#if !STBI_NO_BMP
		private static bool BmpTest(ref Context s)
		{

		}

		private static void* BmpLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int BmpInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_TGA
		private static bool TgaTest(ref Context s)
		{

		}

		private static void* TgaLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int TgaInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_PSD
		private static bool PsdTest(ref Context s)
		{

		}

		private static void* PsdLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri, int bpc)
		{

		}

		private static int PsdInfo(ref Context s, out int x, out int y, out int comp)
		{

		}

		private static int PsdIs16(ref Context s)
		{

		}
#endif

#if !STBI_NO_HDR
		private static bool HdrTest(ref Context s)
		{

		}

		private static float* HdrLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int HdrInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_PIC
		private static bool PicTest(ref Context s)
		{

		}

		private static void* PicLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int PicInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_GIF
		private static bool GifTest(ref Context s)
		{

		}

		private static void* GifLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static void* LoadGifMain(ref Context s, int** delays, out int x, out int y, out int z, out int comp, int req_comp)
		{

		}

		private static int GifInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_PNM
		private static bool PnmTest(ref Context s)
		{

		}

		private static void* PnmLoad(ref Context s, out int x, out int y, out int comp, int req_comp, ref ResultInfo ri)
		{

		}

		private static int PnmInfo(ref Context s, out int x, out int y, out int comp)
		{

		}
#endif

#if !STBI_NO_FAILURE_STRINGS
		private static bool Err(StringView str)
		{
			if (g_failure_reason == null) {
				g_failure_reason = new .(str);
			} else {
				g_failure_reason.Set(str);
			}

			return false;
		}
#endif

		private static void* Malloc(int sz) => Internal.Malloc(sz);
		private static void* Realloc(void* p, int newsz)
		{
			var p;
			Internal.Free(p);
			p = Internal.Malloc(newsz);
			return p;
		}
		private static void* ReallocSized(void* p, int oldsz, int newsz) => Realloc(p, newsz);
		private static void Free(void* p) => Internal.Free(p);

		// stb_image uses ints pervasively, including for offset calculations. therefore the largest decoded image size we can support with the current code, even on 64-bit targets, is INT_MAX. this is not a
		// significant limitation for the intended use case.
		//
		// we do, however, need to make sure our size calculations don't overflow. hence a few helper functions for size calculations that multiply integers together, making sure that they're non-negative
		// and no overflow occurs.
		
		// return 1 if the sum is valid, 0 on overflow. negative terms are considered invalid.
		private static bool AddsizesValid(int a, int b)
		{
			if (b < 0)
				return false;
			
			// now 0 <= b <= INT_MAX, hence also 0 <= INT_MAX - b <= INTMAX.
			// And "a + b <= INT_MAX" (which might overflow) is the same as a <= INT_MAX - b (no overflow)
			return a <= Int.MaxValue - b;
		}

		// returns 1 if the product is valid, 0 on overflow. negative factors are considered invalid.
		private static bool Mul2sizesValid(int a, int b)
		{
			if (a < 0 || b < 0)
				return false;

			if (b == 0)
				return true; // mul-by-0 is always safe

			// portable way to check for no overflows in a*b
			return a <= Int.MaxValue / b;
		}

#if !STBI_NO_JPEG || !STBI_NO_PNG || !STBI_NO_TGA || !STBI_NO_HDR
		// returns 1 if "a*b + add" has no negative terms/factors and doesn't overflow
		private static bool Mad2sizesValid(int a, int b, int add) => Mul2sizesValid(a, b) && AddsizesValid(a * b, add);
#endif
		// returns 1 if "a*b*c + add" has no negative terms/factors and doesn't overflow
		private static bool Mad3sizesValid(int a, int b, int c, int add) => Mul2sizesValid(a, b) && Mul2sizesValid(a * b, c) && AddsizesValid(a * b * c, add);

		// returns 1 if "a*b*c*d + add" has no negative terms/factors and doesn't overflow
#if !STBI_NO_LINEAR || !STBI_NO_HDR
		private static bool Mad4sizesValid(int a, int b, int c, int d, int add) => Mul2sizesValid(a, b) && Mul2sizesValid(a * b, c) && Mul2sizesValid(a * b * c, d) && AddsizesValid(a * b * c * d, add);
#endif

#if !STBI_NO_JPEG || !STBI_NO_PNG || !STBI_NO_TGA || !STBI_NO_HDR
		// mallocs with size overflow checking
		private static void* MallocMad2(int a, int b, int add) => !Mad2sizesValid(a, b, add) ? null : Malloc(a * b + add);
#endif

		private static void* MallocMad3(int a, int b, int c, int add) => !Mad3sizesValid(a, b, c, add) ? null : Malloc(a * b * c + add);

#if !STBI_NO_LINEAR || !STBI_NO_HDR
		private static void* MallocMad4(int a, int b, int c, int d, int add) => !Mad4sizesValid(a, b, c, d, add) ? null : Malloc(a * b * c * d + add);
#endif

		// Err    - error
		// Errpf  - error returning pointer to float
		// Errpuc - error returning pointer to unsigned char
#if STBI_NO_FAILURE_STRINGS
   		private static bool Err(StringView x, StringView y) => false;
#elif STBI_FAILURE_USERMSG
   		private static bool Err(StringView x, StringView y) => Err(y);
#else
   		private static bool Err(StringView x, StringView y) => Err(x);
#endif

		private static float* Errpf(StringView x, StringView y) { Err(x, y); return null; }
		private static uint8* Errpuc(StringView x, StringView y) { Err(x, y); return null; }

#if !STBI_NO_LINEAR
		private static float* LdrToHdr(uint8* data, int x, int y, int comp)
		{
			int i, k, n;
			float* output;
			
			if (data == null)
				return null;
			
			output = (float*)MallocMad4(x, y, comp, sizeof(float), 0);
			
			if (output == null) {
				Free(data);
				return Errpf("outofmem", "Out of memory");
			}
			
			// compute number of non-alpha components
			if (comp & 1 > 0) {
				n = comp;
			} else {
				n = comp - 1;
			}
			
			for (i = 0; i < x * y; ++i)
				for (k=0; k < n; ++k)
					output[i * comp + k] = (float)(Math.Pow(data[i * comp + k] / 255.0f, L2hGamma) * L2hScale);
			
			if (n < comp)
				for (i = 0; i < x * y; ++i)
					output[i * comp + n] = data[i * comp + n] / 255.0f;
			
			Free(data);
			return output;
		}
#endif

#if !STBI_NO_HDR
		private static int Float2int(float x) => (int)x;

		private static uint8* HdrToLdr(float* data, int x, int y, int comp)
		{
			
			int i, k, n;
			uint8* output;

			if (data == null)
				return null;

			output = (uint8*)MallocMad3(x, y, comp, 0);

			if (output == null) {
				Free(data);
				return Errpuc("outofmem", "Out of memory");
			}

			// compute number of non-alpha components
			if (comp & 1 > 0) {
				n = comp;
			} else {
				n = comp - 1;
			}

			for (i = 0; i < x * y; ++i) {
				for (k = 0; k < n; ++k) {
					float z = (float)Math.Pow(data[i * comp + k] * H2lScaleI, H2lGammaI) * 255 + 0.5f;

					if (z < 0)
						z = 0;

					if (z > 255)
						z = 255;

					output[i * comp + k] = (uint8)Float2int(z);
				}

				if (k < comp) {
					float z = data[i * comp + k] * 255 + 0.5f;

					if (z < 0)
						z = 0;

					if (z > 255)
						z = 255;

					output[i * comp + k] = (uint8)Float2int(z);
				}
			}

			Free(data);
			return output;
		}
#endif

		private static bool VerticallyFlipOnLoadGlobal = false;

#if !STBI_THREAD_LOCAL
		private static bool VerticallyFlipOnLoadLocal = VerticallyFlipOnLoadGlobal;
		private const bool VerticallyFlipOnLoadSet = false;
#else
		[ThreadStatic]
		private static bool VerticallyFlipOnLoadLocal;
		[ThreadStatic]
		private static bool VerticallyFlipOnLoadSet;
#endif // STBI_THREAD_LOCAL

		public static bool VerticallyFlipOnLoad() => VerticallyFlipOnLoadSet ? VerticallyFlipOnLoadLocal : VerticallyFlipOnLoadGlobal;
		
		private static void* LoadMain(ref Context s, out int x, out int y, out int comp, int req_comp, out ResultInfo ri, int bpc)
		{
			Internal.MemSet(&ri, 0, sizeof(ResultInfo)); // make sure it's initialized if we add new fields
			ri.bits_per_channel = 8; // default is 8 so most paths don't have to be changed
			ri.channel_order = STBI_ORDER_RGB; // all current input & output are this, but this is here so we can add BGR order
			ri.num_channels = 0;

#if !STBI_NO_JPEG
			if (JpegTest(ref s))
				return JpegLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_PNG
			if (PngTest(ref s))
				return PngLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_BMP
			if (BmpTest(ref s))
				return BmpLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_GIF
			if (GifTest(ref s))
				return GifLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_PSD
			if (PsdTest(ref s))
				return PsdLoad(ref s, out x, out y, out comp, req_comp, ref ri, bpc);
#endif
#if !STBI_NO_PIC
			if (PicTest(ref s))
				return PicLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_PNM
			if (PnmTest(ref s))
				return PnmLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif
#if !STBI_NO_HDR
			if (HdrTest(ref s)) {
				float* hdr = HdrLoad(ref s, out x, out y, out comp, req_comp, ref ri);
				return HdrToLdr(hdr, x, y, req_comp > 0 ? req_comp : comp);
			}
#endif
#if !STBI_NO_TGA
			// test tga last because it's a crappy test!
			if (TgaTest(ref s))
				return TgaLoad(ref s, out x, out y, out comp, req_comp, ref ri);
#endif

			x = y = comp = 0;
			return Errpuc("unknown image type", "Image not of any known type, or corrupt");
		}

		private static uint8* Convert16To8(uint16* orig, int w, int h, int channels)
		{
			int i;
			int img_len = w * h * channels;
			uint8* reduced;
			
			reduced = (uint8*)Malloc(img_len);
			
			if (reduced == null)
				return Errpuc("outofmem", "Out of memory");
			
			for (i = 0; i < img_len; ++i)
			  	reduced[i] = (uint8)((orig[i] >> 8) & 0xFF); // top half of each byte is sufficient approx of 16->8 bit scaling
			
			Free(orig);
			return reduced;
		}

		private static uint16* Convert8To16(uint8* orig, int w, int h, int channels)
		{
			int i;
			int img_len = w * h * channels;
			uint16* enlarged;
			
			enlarged = (uint16*)Malloc(img_len * 2);
			
			if (enlarged == null)
				return (uint16*)Errpuc("outofmem", "Out of memory");
			
			for (i = 0; i < img_len; ++i)
				enlarged[i] = (((uint16)orig[i]) << 8) + orig[i]; // replicate to high and low byte, maps 0->0, 255->0xffff
			
			Free(orig);
			return enlarged;
		}

		private static void VerticalFlip(void* image, int w, int h, int bytes_per_pixel)
		{
			int row;
			int bytes_per_row = w * bytes_per_pixel;
			uint8[2048] temp;
			uint8* bytes = (uint8*)image;
			
			for (row = 0; row < (h >> 1); row++) {
				uint8* row0 = bytes + row * bytes_per_row;
				uint8* row1 = bytes + (h - row - 1) * bytes_per_row;
				// swap row0 with row1
				int bytes_left = bytes_per_row;

				while (bytes_left > 0) {
					int bytes_copy = (bytes_left < sizeof(uint8[2048])) ? bytes_left : sizeof(uint8[2048]);
					Internal.MemCpy(&temp[0], row0, bytes_copy);
					Internal.MemCpy(row0, row1, bytes_copy);
					Internal.MemCpy(row1, &temp[0], bytes_copy);
					row0 += bytes_copy;
					row1 += bytes_copy;
					bytes_left -= bytes_copy;
				}
			}
		}
		
#if !STBI_NO_GIF
		private static void VerticalFlipSlices(void* image, int w, int h, int z, int bytes_per_pixel)
		{
			int slice;
			int slice_size = w * h * bytes_per_pixel;
			
			uint8* bytes = (uint8*)image;

			for (slice = 0; slice < z; ++slice) {
				VerticalFlip(bytes, w, h, bytes_per_pixel);
				bytes += slice_size;
			}
		}
#endif

		private static uint8* LoadAndPostprocess8bit(ref Context s, out int x, out int y, out int comp, int req_comp)
		{
			ResultInfo ri;
			void* result = LoadMain(ref s, out x, out y, out comp, req_comp, out ri, 8);
			
			if (result == null)
				return null;
			
			// it is the responsibility of the loaders to make sure we get either 8 or 16 bit.
			Debug.Assert(ri.bits_per_channel == 8 || ri.bits_per_channel == 16);
			
			if (ri.bits_per_channel != 8) {
				result = Convert16To8((uint16*)result, x, y, req_comp == 0 ? comp : req_comp);
				ri.bits_per_channel = 8;
			}
			
			// @TODO: move stbi__convert_format to here
			
			if (VerticallyFlipOnLoad()) {
				int channels = req_comp > 0 ? req_comp : comp;
				VerticalFlip(result, x, y, channels * sizeof(uint8));
			}
			
			return (uint8*)result;
		}

		private static uint16* LoadAndPostprocess16bit(ref Context s, out int x, out int y, out int comp, int req_comp)
		{
			ResultInfo ri;
			void* result = LoadMain(ref s, out x, out y, out comp, req_comp, out ri, 16);
			
			if (result == null)
				return null;
			
			// it is the responsibility of the loaders to make sure we get either 8 or 16 bit.
			Debug.Assert(ri.bits_per_channel == 8 || ri.bits_per_channel == 16);
			
			if (ri.bits_per_channel != 16) {
				result = Convert8To16((uint8*)result, x, y, req_comp == 0 ? comp : req_comp);
				ri.bits_per_channel = 16;
			}
			
			// @TODO: move stbi__convert_format16 to here
			// @TODO: special case RGB-to-Y (and RGBA-to-YA) for 8-bit-to-16-bit case to keep more precision
			if (VerticallyFlipOnLoad()) {
				int channels = req_comp > 0 ? req_comp : comp;
				VerticalFlip(result, x, y, channels * sizeof(uint16));
			}
			
			return (uint16*)result;
		}

#if !STBI_NO_HDR && !STBI_NO_LINEAR
		private static void FloatPostprocess(float* result, int x, int y, int comp, int req_comp)
		{
			if (VerticallyFlipOnLoad() && result != null) {
				int channels = req_comp > 0 ? req_comp : comp;
				VerticalFlip(result, x, y, channels * sizeof(float));
			}
		}
#endif

#if STBI_WINDOWS_UTF8
		[CLink, CallingConvention(.Stdcall)]
		private extern static int MultiByteToWideChar(uint cp, uint flags, char8* str, int cbmb, char16* widestr, int cchwide);
		[CLink, CallingConvention(.Stdcall)]
		private extern static int WideCharToMultiByte(uint cp, uint flags, char16* widestr, int cchwide, char8* str, int cbmb, char8* defchar, int* used_default);

		public static int ConvertWcharToUtf8(char8* buffer, int bufferlen, char16* input) => WideCharToMultiByte(65001 /* UTF8 */, 0, input, -1, buffer, bufferlen, null, null);
#endif

		private static Platform.BfpFile* Fopen(StringView filename, FileMode mode, FileAccess access)
		{
			Platform.BfpFileResult fr = .Ok;
			Platform.BfpFileCreateKind createKind = .CreateAlways;
			Platform.BfpFileCreateFlags createFlags = .None | .ShareRead;
			
			switch (mode)
			{
			case .Append:
				createKind = .CreateAlways;
				createFlags |= .Append;
			case .Create:
				createKind = .CreateAlways;
			case .CreateNew:
				createKind = .CreateIfNotExists;
			case .Open:
				createKind = .OpenExisting;
			case .OpenOrCreate:
				createKind = .CreateAlways;
			case .Truncate:
				createKind = .CreateAlways;
				createFlags |= .Truncate;
			}

			if (access.HasFlag(.Read))
				createFlags |= .Read;

			if (access.HasFlag(.Write))
				createFlags |= .Write;

			Platform.BfpFile* f = Platform.BfpFile_Create(filename.ToScopeCStr!(128), createKind, createFlags, .Normal, &fr);

			if ((f == null) || (fr != .Ok))
				return null;

			return f;
		}

		//////////////////////////////////////////////////////////////////////////////
		//
		// Common code used by all image loaders
		//
		private const int SCAN_load   = 0;
		private const int SCAN_type   = 1;
		private const int SCAN_header = 2;

		[Inline]
		private static uint8 Get8(ref Context s)
		{
			if (s.img_buffer < s.img_buffer_end)
				return *s.img_buffer++;

			if (s.read_from_callbacks) {
				RefillBuffer(ref s);
				return *s.img_buffer++;
			}

			return 0;
		}

#if !(STBI_NO_JPEG && STBI_NO_HDR && STBI_NO_PIC && STBI_NO_PNM)
		[Inline]
		private static bool AtEof(ref Context s)
		{
			if (s.io.read != null) {
				if (!s.io.eof(s.io_user_data))
					return false;

				// if feof() is true, check if buffer = end
				// special case: we've only got the special 0 character at the end
				if (!s.read_from_callbacks)
					return true;
			}

			return s.img_buffer >= s.img_buffer_end;
		}
#endif

#if !(STBI_NO_JPEG && STBI_NO_PNG && STBI_NO_BMP && STBI_NO_PSD && STBI_NO_TGA && STBI_NO_GIF && STBI_NO_PIC)
		private static void Skip(ref Context s, int n)
		{
			if (n == 0) return;  // already there!

			if (n < 0) {
				s.img_buffer = s.img_buffer_end;
				return;
			}

			if (s.io.read != null) {
				int blen = (int)(s.img_buffer_end - s.img_buffer);

				if (blen < n) {
					s.img_buffer = s.img_buffer_end;
					s.io.skip(s.io_user_data, n - blen);
					return;
				}
			}

			s.img_buffer += n;
		}
#endif

#if !(STBI_NO_PNG && STBI_NO_TGA && STBI_NO_HDR && STBI_NO_PNM)
		private static bool Getn(ref Context s, uint8* buffer, int n)
		{
			if (s.io.read != null) {
				int blen = (int)(s.img_buffer_end - s.img_buffer);

				if (blen < n) {
					bool res;
					int count;

					Internal.MemCpy(buffer, s.img_buffer, blen);

					count = s.io.read(s.io_user_data, (char8*)buffer + blen, n - blen);
					res = (count == (n - blen));
					s.img_buffer = s.img_buffer_end;
					return res;
				}
			}

			if (s.img_buffer + n <= s.img_buffer_end) {
				Internal.MemCpy(buffer, s.img_buffer, n);
				s.img_buffer += n;
				return true;
			} else {
				return false;
			}
		}
#endif

#if !(STBI_NO_JPEG && STBI_NO_PNG && STBI_NO_PSD && STBI_NO_PIC)
		private static int Get16be(ref Context s)
		{
			int z = Get8(ref s);
			return (z << 8) + Get8(ref s);
		}
#endif

#if !(STBI_NO_PNG && STBI_NO_PSD && STBI_NO_PIC)
		private static uint32 Get32be(ref Context s)
		{
			uint32 z = (uint32)Get16be(ref s);
			return (z << 16) + (uint32)Get16be(ref s);
		}
#endif

#if !(STBI_NO_BMP && STBI_NO_TGA && STBI_NO_GIF)
		private static int Get16le(ref Context s)
		{
			int z = Get8(ref s);
			return z + (((int)Get8(ref s)) << 8);
		}
#endif

#if !STBI_NO_BMP
		private static uint32 Get32le(ref Context s)
		{
			uint32 z = (uint32)Get16le(ref s);
			return z + (((uint32)Get16le(ref s)) << 16);
		}
#endif

		private static uint8 BYTECAST(int x) => (uint8)(x & 255);  // truncate int to byte without warnings

#if !(STBI_NO_JPEG && STBI_NO_PNG && STBI_NO_BMP && STBI_NO_PSD && STBI_NO_TGA && STBI_NO_GIF && STBI_NO_PIC && STBI_NO_PNM)
		//////////////////////////////////////////////////////////////////////////////
		//
		//  generic converter from built-in img_n to req_comp
		//    individual types do this automatically as much as possible (e.g. jpeg does all cases internally since it needs to colorspace convert anyway,
		//    and it never has alpha, so very few cases ). png can automatically interleave an alpha=255 channel, but falls back to this for other cases
		//
		//  assume data buffer is malloced, so malloc a new one and free that one only failure mode is malloc failing
		private static uint8 ComputeY(int r, int g, int b) => (uint8)(((r * 77) + (g * 150) + (29 * b)) >> 8);
#endif

#if !(STBI_NO_PNG && STBI_NO_BMP && STBI_NO_PSD && STBI_NO_TGA && STBI_NO_GIF && STBI_NO_PIC && STBI_NO_PNM)
		private static uint8* ConvertFormat(uint8* data, int img_n, int req_comp, uint x, uint y)
		{
			uint i;
			int j;
			uint8* good;
			
			if (req_comp == img_n)
				return data;

			Debug.Assert(req_comp >= 1 && req_comp <= 4);
			
			good = (uint8*)MallocMad3(req_comp, (int)x, (int)y, 0);
			
			if (good == null) {
				Free(data);
				return Errpuc("outofmem", "Out of memory");
			}
			
			for (j = 0; j < (int)y; ++j) {
				uint8* src  = data + j * (int)x * img_n;
				uint8* dest = good + j * (int)x * req_comp;

				int COMBO(int a, int b) => (a * 8 + b);

				// convert source image with img_n components to one with req_comp components; avoid switch per pixel, so use switch per scanline and massive macros
				switch (COMBO(img_n, req_comp)) {
				case COMBO(1, 2): for(i = x - 1; i >= 0; --i, src += 1, dest += 2) { dest[0] = src[0];                           dest[1] = 255;                                     }
				case COMBO(1, 3): for(i = x - 1; i >= 0; --i, src += 1, dest += 3) { dest[0] = dest[1] = dest[2] = src[0];                                                          }
				case COMBO(1, 4): for(i = x - 1; i >= 0; --i, src += 1, dest += 4) { dest[0] = dest[1] = dest[2] = src[0];       dest[3] = 255;                                     }
				case COMBO(2, 1): for(i = x - 1; i >= 0; --i, src += 2, dest += 1) { dest[0] = src[0];                                                                              }
				case COMBO(2, 3): for(i = x - 1; i >= 0; --i, src += 2, dest += 3) { dest[0] = dest[1] = dest[2] = src[0];                                                          }
				case COMBO(2, 4): for(i = x - 1; i >= 0; --i, src += 2, dest += 4) { dest[0] = dest[1] = dest[2] = src[0];       dest[3] = src[1];                                  }
				case COMBO(3, 4): for(i = x - 1; i >= 0; --i, src += 3, dest += 4) { dest[0] = src[0];                           dest[1] = src[1]; dest[2] = src[2]; dest[3] = 255; }
				case COMBO(3, 1): for(i = x - 1; i >= 0; --i, src += 3, dest += 1) { dest[0] = ComputeY(src[0], src[1], src[2]);                                                    }
				case COMBO(3, 2): for(i = x - 1; i >= 0; --i, src += 3, dest += 2) { dest[0] = ComputeY(src[0], src[1], src[2]); dest[1] = 255;                                     }
				case COMBO(4, 1): for(i = x - 1; i >= 0; --i, src += 4, dest += 1) { dest[0] = ComputeY(src[0], src[1], src[2]);                                                    }
				case COMBO(4, 2): for(i = x - 1; i >= 0; --i, src += 4, dest += 2) { dest[0] = ComputeY(src[0], src[1], src[2]); dest[1] = src[3];                                  }
				case COMBO(4, 3): for(i = x - 1; i >= 0; --i, src += 4, dest += 3) { dest[0] = src[0];                           dest[1] = src[1]; dest[2] = src[2];                }
				default: Debug.Assert(false); Free(data); Free(good); return Errpuc("unsupported", "Unsupported format conversion");
				}
			}

			Free(data);
			return good;
		}
#endif

#if !(STBI_NO_PNG && STBI_NO_PSD)
		private static uint16 ComputeY16(int r, int g, int b) => (uint16)((( r* 77) + (g * 150) + (29 * b)) >> 8);
#endif

#if !(STBI_NO_PNG && STBI_NO_PSD)
		private static uint16* ConvertFormat16(uint16* data, int img_n, int req_comp, uint x, uint y)
		{
			uint i;
			int j;
			uint16* good;
			
			if (req_comp == img_n)
				return data;
			
			Debug.Assert(req_comp >= 1 && req_comp <= 4);
			
			good = (uint16*)Malloc(req_comp * (int)x * (int)y * 2);

			if (good == null) {
				Free(data);
				return (uint16*)Errpuc("outofmem", "Out of memory");
			}

			for (j = 0; j < (int)y; ++j) {
				uint16* src  = data + j * (int)x * img_n;
				uint16* dest = good + j * (int)x * req_comp;

				int COMBO(int a, int b) => a * 8 + b;

				// convert source image with img_n components to one with req_comp components; avoid switch per pixel, so use switch per scanline and massive macros
				switch (COMBO(img_n, req_comp)) {
				case COMBO(1, 2): for(i = x - 1; i >= 0; --i, src += 1, dest += 2) { dest[0] = src[0];                             dest[1] = 0xffff;                                     }
				case COMBO(1, 3): for(i = x - 1; i >= 0; --i, src += 1, dest += 3) { dest[0] = dest[1] = dest[2] = src[0];                                                               }
				case COMBO(1, 4): for(i = x - 1; i >= 0; --i, src += 1, dest += 4) { dest[0] = dest[1] = dest[2] = src[0];         dest[3] = 0xffff;                                     }
				case COMBO(2, 1): for(i = x - 1; i >= 0; --i, src += 2, dest += 1) { dest[0] = src[0];                                                                                   }
				case COMBO(2, 3): for(i = x - 1; i >= 0; --i, src += 2, dest += 3) { dest[0] = dest[1] = dest[2] = src[0];                                                               }
				case COMBO(2, 4): for(i = x - 1; i >= 0; --i, src += 2, dest += 4) { dest[0] = dest[1] = dest[2] = src[0];         dest[3] = src[1];                                     }
				case COMBO(3, 4): for(i = x - 1; i >= 0; --i, src += 3, dest += 4) { dest[0] = src[0];                             dest[1] = src[1]; dest[2] = src[2]; dest[3] = 0xffff; }
				case COMBO(3, 1): for(i = x - 1; i >= 0; --i, src += 3, dest += 1) { dest[0] = ComputeY16(src[0], src[1], src[2]);                                                       }
				case COMBO(3, 2): for(i = x - 1; i >= 0; --i, src += 3, dest += 2) { dest[0] = ComputeY16(src[0], src[1], src[2]); dest[1] = 0xffff;                                     }
				case COMBO(4, 1): for(i = x - 1; i >= 0; --i, src += 4, dest += 1) { dest[0] = ComputeY16(src[0], src[1], src[2]);                                                       }
				case COMBO(4, 2): for(i = x - 1; i >= 0; --i, src += 4, dest += 2) { dest[0] = ComputeY16(src[0], src[1], src[2]); dest[1] = src[3];                                     }
				case COMBO(4, 3): for(i = x - 1; i >= 0; --i, src += 4, dest += 3) { dest[0] = src[0];                             dest[1] = src[1]; dest[2] = src[2];                   }
				default: Debug.Assert(false); Free(data); Free(good); return (uint16*)Errpuc("unsupported", "Unsupported format conversion");
				}
			}

			Free(data);
			return good;
		}
#endif

		//////////////////////////////////////////////////////////////////////////////
		//
		//  "baseline" JPEG/JFIF decoder
		//
		//    simple implementation
		//      - doesn't support delayed output of y-dimension
		//      - simple interface (only one output format: 8-bit interleaved RGB)
		//      - doesn't try to recover corrupt jpegs
		//      - doesn't allow partial loading, loading multiple at once
		//      - still fast on x86 (copying globals into locals doesn't help x86)
		//      - allocates lots of intermediate memory (full size of all components)
		//        - non-interleaved case requires this anyway
		//        - allows good upsampling (see next)
		//    high-quality
		//      - upsampled channels are bilinearly interpolated, even across blocks
		//      - quality integer IDCT derived from IJG's 'slow'
		//    performance
		//      - fast huffman; reasonable integer IDCT
		//      - some SIMD kernels for common paths on targets with SSE2/NEON
		//      - uses a lot of intermediate memory, could cache poorly
#if !STBI_NO_JPEG
		// huffman decoding acceleration
		private const int FAST_BITS = 9;  // larger handles more cases; smaller stomps less cache

		private struct huffman
		{
			public uint8[1 << FAST_BITS] fast;
			// weirdly, repacking this into AoS is a 10% speed loss, instead of a win
			public uint16[256] code;
			public uint8[256] values;
			public uint8[257] size;
			public uint[18] maxcode;
			public int[17] delta;   // old 'firstsymbol' - old 'firstcode'
		}

		private struct jpeg
		{
			public Context* s;
			public huffman[4] huff_dc;
			public huffman[4] huff_ac;
			public uint16[4][64] dequant;
			public int16[4][1 << FAST_BITS] fast_ac;
		
			// sizes for components, interleaved MCUs
			public int img_h_max, img_v_max;
			public int img_mcu_x, img_mcu_y;
			public int img_mcu_w, img_mcu_h;
		
			// definition of jpeg image component
			public img_comp_struct[4] img_comp;
		
			public uint32 code_buffer; // jpeg entropy-coded buffer
			public int code_bits;      // number of valid bits
			public uint8 marker;       // marker seen while filling entropy buffer
			public bool nomore;        // flag if we saw a marker so must stop
		
			public int progressive;
			public int spec_start;
			public int spec_end;
			public int succ_high;
			public int succ_low;
			public int eob_run;
			public int jfif;
			public int app14_color_transform; // Adobe APP14 tag
			public int rgb;
		
			public int scan_n;
			public int[4] order;
			public int restart_interval, todo;
		
			// kernels
			public function void(uint8* outVal, int out_stride, int16[64] data) idct_block_kernel;
			public function void(uint8* outVal, uint8* y, uint8* pcb, uint8* pcr, int count, int step) YCbCr_to_RGB_kernel;
			public function uint8*(uint8* outVal, uint8* in_near, uint8* in_far, int w, int hs) resample_row_hv_2_kernel;

			public struct img_comp_struct
			{
				public int id;
				public int h, v;
				public int tq;
				public int hd, ha;
				public int dc_pred;
		
				public int x, y, w2, h2;
				public uint8* data;
				public void* raw_data, raw_coeff;
				public uint8* linebuf;
				public int16* coeff;              // progressive only
				public int coeff_w, coeff_h;      // number of 8x8 coefficient blocks
			}
		}

		private static bool BuildHuffman(ref huffman h, int* count)
		{
			int i, j, k = 0;
			uint code;

			// build size list for each symbol (from JPEG spec)
			for (i = 0; i < 16; ++i)
				for (j = 0; j < count[i]; ++j)
					h.size[k++] = (uint8)(i + 1);

			h.size[k] = 0;
		
			// compute actual symbols (from jpeg spec)
			code = 0;
			k = 0;

			for(j = 1; j <= 16; ++j) {
				// compute delta to add to code to compute symbol id
				h.delta[j] = k - (int)code;

				if (h.size[k] == j) {
					while (h.size[k] == j)
						h.code[k++] = (uint16)(code++);

					if (code - 1 >= (1u << j))
						return Err("bad code lengths", "Corrupt JPEG");
				}

				// compute largest code + 1 for this size, preshifted as needed later
				h.maxcode[j] = code << (16 - j);
				code <<= 1;
			}

			h.maxcode[j] = 0xffffffff;
		
			// build non-spec acceleration table; 255 is flag for not-accelerated
			Internal.MemSet(&h.fast[0], 255, 1 << FAST_BITS);

			for (i=0; i < k; ++i) {
				int s = h.size[i];

				if (s <= FAST_BITS) {
					int c = h.code[i] << (FAST_BITS - s);
					int m = 1 << (FAST_BITS - s);
					for (j = 0; j < m; ++j) {
						h.fast[c + j] = (uint8)i;
					}
				}
			}

			return true;
		}

		// build a table that decodes both magnitude and value of small ACs in one go.
		private static void BuildFastAc(int16* fast_ac, ref huffman h)
		{
			int i;

			for (i = 0; i < (1 << FAST_BITS); ++i) {
				uint8 fast = h.fast[i];
				fast_ac[i] = 0;

				if (fast < 255) {
					int rs = h.values[fast];
					int run = (rs >> 4) & 15;
					int magbits = rs & 15;
					int len = h.size[fast];

					if (magbits > 0 && len + magbits <= FAST_BITS) {
						// magnitude code followed by receive_extend code
						int k = ((i << len) & ((1 << FAST_BITS) - 1)) >> (FAST_BITS - magbits);
						int m = 1 << (magbits - 1);

						if (k < m)
							k += (int)((~0U << magbits) + 1);

						// if the result is small enough, we can fit it in fast_ac table
						if (k >= -128 && k <= 127)
							fast_ac[i] = (int16)((k * 256) + (run * 16) + (len + magbits));
					}
				}
			}
		}

		private static void GrowBufferUnsafe(ref jpeg j)
		{
			repeat {
				uint b = j.nomore ? 0 : Get8(ref *j.s);

				if (b == 0xff) {
					int c = Get8(ref *j.s);

					while (c == 0xff)
						c = Get8(ref *j.s); // consume fill bytes

					if (c != 0) {
						j.marker = (uint8)c;
						j.nomore = true;
						return;
					}
				}

				j.code_buffer |= (uint32)b << (24 - j.code_bits);
				j.code_bits += 8;
			} while (j.code_bits <= 24);
		}

		// (1 << n) - 1
		private static uint32[] Bmask = new .[17](0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767, 65535) ~ delete _;

		// decode a jpeg huffman value from the bitstream
		[Inline]
		private static int JpegHuffDecode(ref jpeg j, ref huffman h)
		{
			uint temp;
			int c, k;

			if (j.code_bits < 16)
				GrowBufferUnsafe(ref j);

			// look at the top FAST_BITS and determine what symbol ID it is,
			// if the code is <= FAST_BITS
			c = (j.code_buffer >> (32 - FAST_BITS)) & ((1 << FAST_BITS) - 1);
			k = h.fast[c];

			if (k < 255) {
				int s = h.size[k];

				if (s > j.code_bits)
					return -1;

				j.code_buffer <<= s;
				j.code_bits -= s;
				return h.values[k];
			}

			// naive test is to shift the code_buffer down so k bits are
			// valid, then test against maxcode. To speed this up, we've
			// preshifted maxcode left so that it has (16-k) 0s at the
			// end; in other words, regardless of the number of bits, it
			// wants to be compared against something shifted to have 16;
			// that way we don't need to shift inside the loop.
			temp = j.code_buffer >> 16;

			for (k = FAST_BITS + 1; ; ++k)
				if (temp < h.maxcode[k])
					break;

			if (k == 17) {
				// error! code not found
				j.code_bits -= 16;
				return -1;
			}

			if (k > j.code_bits)
				return -1;

			// convert the huffman code to the symbol id
			c = ((j.code_buffer >> (32 - k)) & Bmask[k]) + h.delta[k];
			Debug.Assert((((j.code_buffer) >> (32 - h.size[c])) & Bmask[h.size[c]]) == h.code[c]);

			// convert the id to a symbol
			j.code_bits -= k;
			j.code_buffer <<= k;
			return h.values[c];
		}

		// bias[n] = (-1 << n) + 1
		private static int[] Jbias = new .[16](0, -1, -3, -7, -15, -31, -63, -127, -255, -511, -1023, -2047, -4095, -8191, -16383, -32767) ~ delete _;

		// combined JPEG 'receive' and JPEG 'extend', since baseline always extends everything it receives.
		[Inline]
		private static int ExtendReceive(ref jpeg j, int n)
		{
			uint k;
			int sgn;

			if (j.code_bits < n)
				GrowBufferUnsafe(ref j);

			sgn = (int32)j.code_buffer >> 31; // sign bit is always in MSB
			k = lrot(j.code_buffer, (uint32)n);

			if (n < 0 || n >= Bmask.Count)
				return 0;

			j.code_buffer = (uint32)(k & ~Bmask[n]);
			k &= Bmask[n];
			j.code_bits -= n;
			return (int)k + (Jbias[n] & ~sgn);
		}

		// get some unsigned bits
		[Inline]
		private static int JpegGetBits(ref jpeg j, int n)
		{
			uint k;

			if (j.code_bits < n)
				GrowBufferUnsafe(ref j);

			k = lrot(j.code_buffer, (uint32)n);
			j.code_buffer = (uint32)(k & ~Bmask[n]);
			k &= Bmask[n];
			j.code_bits -= n;
			return (int)k;
		}

		[Inline]
		private static int JpegGetBit(ref jpeg j)
		{
			uint k;

			if (j.code_bits < 1)
				GrowBufferUnsafe(ref j);

			k = j.code_buffer;
			j.code_buffer <<= 1;
			--j.code_bits;
			return (int)(k & 0x80000000);
		}

		// given a value that's at position X in the zigzag stream, where does it appear in the 8x8 matrix coded as row-major?
		private static uint8[] JpegDezigzag = new .[64+15](
			0,  1,  8, 16,  9,  2,  3, 10,
			17, 24, 32, 25, 18, 11,  4,  5,
			12, 19, 26, 33, 40, 48, 41, 34,
			27, 20, 13,  6,  7, 14, 21, 28,
			35, 42, 49, 56, 57, 50, 43, 36,
			29, 22, 15, 23, 30, 37, 44, 51,
			58, 59, 52, 45, 38, 31, 39, 46,
			53, 60, 61, 54, 47, 55, 62, 63,
			// let corrupt input sample past end
			63, 63, 63, 63, 63, 63, 63, 63,
			63, 63, 63, 63, 63, 63, 63
		) ~ delete _;
		
		// decode one 64-entry block--
		private static bool JpegDecodeBlock(ref jpeg j, int16[64] data, ref huffman hdc, ref huffman hac, int16* fac, int b, uint16* dequant)
		{
			var data;
			int diff, dc, k;
			int t;
		
			if (j.code_bits < 16)
				GrowBufferUnsafe(ref j);

			t = JpegHuffDecode(ref j, ref hdc);

			if (t < 0)
				return Err("bad huffman code", "Corrupt JPEG");
		
			// 0 all the ac values now so we can do it 32-bits at a time
			Internal.MemSet(&data[0], 0, 64 * sizeof(int16));
		
			diff = t > 0 ? ExtendReceive(ref j, t) : 0;
			dc = j.img_comp[b].dc_pred + diff;
			j.img_comp[b].dc_pred = dc;
			data[0] = (int16)(dc * dequant[0]);
		
			// decode AC components, see JPEG spec
			k = 1;

			repeat {
				uint zig;
				int c, r, s;

				if (j.code_bits < 16)
					GrowBufferUnsafe(ref j);

				c = (j.code_buffer >> (32 - FAST_BITS)) & ((1 << FAST_BITS) - 1);
				r = fac[c];

				if (r > 0) { // fast-AC path
					k += (r >> 4) & 15; // run
					s = r & 15; // combined length
					j.code_buffer <<= s;
					j.code_bits -= s;
					// decode into unzigzag'd location
					zig = JpegDezigzag[k++];
					data[zig] = (int16)((r >> 8) * dequant[zig]);
				} else {
					int rs = JpegHuffDecode(ref j, ref hac);

					if (rs < 0)
						return Err("bad huffman code","Corrupt JPEG");

					s = rs & 15;
					r = rs >> 4;

					if (s == 0) {
						if (rs != 0xf0)
							break; // end block

						k += 16;
					} else {
						k += r;
						// decode into unzigzag'd location
						zig = JpegDezigzag[k++];
						data[zig] = (int16)(ExtendReceive(ref j, s) * dequant[zig]);
					}
				}
			} while (k < 64);

			return true;
		}

		private static bool JpegDecodeBlockProgDc(ref jpeg j, int16[64] data, ref huffman hdc, int b)
		{
			var data;
			int diff, dc;
			int t;

			if (j.spec_end != 0)
				return Err("can't merge dc and ac", "Corrupt JPEG");

			if (j.code_bits < 16)
				GrowBufferUnsafe(ref j);

			if (j.succ_high == 0) {
				// first scan for DC coefficient, must be first
				Internal.MemSet(&data[0], 0, 64 * sizeof(int16)); // 0 all the ac values now
				t = JpegHuffDecode(ref j, ref hdc);

				if (t == -1)
					return Err("can't merge dc and ac", "Corrupt JPEG");

				diff = t > 0 ? ExtendReceive(ref j, t) : 0;
	
				dc = j.img_comp[b].dc_pred + diff;
				j.img_comp[b].dc_pred = dc;
				data[0] = (int16)(dc << j.succ_low);
			} else {
				// refinement scan for DC coefficient
				if (JpegGetBit(ref j) > 0)
				 data[0] += (int16)(1 << j.succ_low);
			}

			return true;
		}

		// @OPTIMIZE: store non-zigzagged during the decode passes, and only de-zigzag when dequantizing
		private static bool stbi__jpeg_decode_block_prog_ac(ref jpeg j, int16[64] data, ref huffman hac, int16* fac)
		{
			var data;
			int k;

			if (j.spec_start == 0)
				return Err("can't merge dc and ac", "Corrupt JPEG");
		
			if (j.succ_high == 0) {
				int shift = j.succ_low;

				if (j.eob_run > 0) {
					--j.eob_run;
					return true;
				}

				k = j.spec_start;

				repeat {
					uint zig;
					int c, r, s;

					if (j.code_bits < 16)
						GrowBufferUnsafe(ref j);

					c = (j.code_buffer >> (32 - FAST_BITS)) & ((1 << FAST_BITS) - 1);
					r = fac[c];

					if (r > 0) { // fast-AC path
						k += (r >> 4) & 15; // run
						s = r & 15; // combined length
						j.code_buffer <<= s;
						j.code_bits -= s;
						zig =  JpegDezigzag[k++];
						data[zig] = (int16)((r >> 8) << shift);
					} else {
						int rs = JpegHuffDecode(ref j, ref hac);

						if (rs < 0)
							return Err("bad huffman code","Corrupt JPEG");

						s = rs & 15;
						r = rs >> 4;
						if (s == 0) {
							if (r < 15) {
								j.eob_run = (1 << r);

								if (r > 0)
									j.eob_run += JpegGetBits(ref j, r);

								--j.eob_run;
								break;
							}
							k += 16;
						} else {
							k += r;
							zig = JpegDezigzag[k++];
							data[zig] = (int16)(ExtendReceive(ref j, s) << shift);
						}
					}
				} while (k <= j.spec_end);
			} else {
			// refinement scan for these AC coefficients
		
			int16 bit = (int16)(1 << j.succ_low);
		
			if (j.eob_run > 0) {
				--j.eob_run;

				for (k = j.spec_start; k <= j.spec_end; ++k) {
					int16* p = &data[JpegDezigzag[k]];

					if (*p != 0)
						if (JpegGetBit(ref j) > 0)
							if ((*p & bit) == 0) {
								if (*p > 0) {
									*p += bit;
								} else {
									*p -= bit;
								}
							}
				}
			} else {
				k = j.spec_start;

				repeat {
					int r, s;
					int rs = JpegHuffDecode(ref j, ref hac); // @OPTIMIZE see if we can use the fast path here, advance-by-r is so slow, eh

					if (rs < 0)
						return Err("bad huffman code","Corrupt JPEG");

					s = rs & 15;
					r = rs >> 4;

					if (s == 0) {
						if (r < 15) {
							j.eob_run = (1 << r) - 1;

							if (r > 0)
								j.eob_run += JpegGetBits(ref j, r);

							r = 64; // force end of block
						} else {
							// r=15 s=0 should write 16 0s, so we just do a run of 15 0s and then write s (which is 0), so we don't have to do anything special here
						}
					} else {
						if (s != 1)
							return Err("bad huffman code", "Corrupt JPEG");

						// sign bit
						if (JpegGetBit(ref j) > 0) {
							s = bit;
						} else {
							s = -bit;
						}
					}
		
					// advance by r
					while (k <= j.spec_end) {
						int16* p = &data[JpegDezigzag[k++]];

						if (*p != 0) {
							if (JpegGetBit(ref j) > 0)
								if ((*p & bit) == 0) {
									if (*p > 0) {
										*p += bit;
									} else {
										*p -= bit;
									}
								}
							} else {
								if (r == 0) {
									*p = (int16)s;
									break;
								}

								--r;
							}
						}
					} while (k <= j.spec_end);
				}
			}

			return true;
		}
#endif
	}
}

/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
