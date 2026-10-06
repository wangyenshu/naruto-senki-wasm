/* Minimal ALUT for emscripten: context setup only. Game audio is ogg (vorbisfile path). */
#pragma once
#include <AL/al.h>
#include <AL/alc.h>
static inline ALboolean alutInit(int *argc, char **argv)
{
	ALCdevice *d = alcOpenDevice(NULL);
	ALCcontext *c = d ? alcCreateContext(d, NULL) : NULL;
	return c && alcMakeContextCurrent(c);
}
static inline ALboolean alutExit(void) { return AL_TRUE; }
static inline ALuint alutCreateBufferFromFile(const char *f) { return AL_NONE; }
