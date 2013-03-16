CC := gcc
AR := ar
CFLAGS := -msse2 -D HAVE_SSE2 -D HAVE_LIBJPEG -D HAVE_LIBPNG -D HAVE_GSL -D HAVE_FFTW3 -D HAVE_CBLAS -fPIC `pkg-config blas --cflags`
LDFLAGS := -lm -ljpeg -lpng -lz -lgsl -lfftw3f -lfftw3 -lblas `pkg-config blas --libs`
