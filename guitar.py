import subprocess
import os
import time 
import threading
import re

class Guitar(object):
	chords = {
		'Am': ['',0,2,2,1,0],
		'Em': [0,2,2,0,0,0],
		'E7': [0,2,0,1,0,0],
		'F': [1,3,3,2,1,1],
		'G': [3,2,0,0,0,3],
		'C': [3,2,0,0,0,3],
		'D': ['','',0,2,3,2],
		'Dm7': ['','',0,2,3,2],
	}

	def __init__(self, tuning=None, capo=0):
		self.tuning = tuning or [82.41, 110.0, 146.83, 196.00, 246.94, 329.63]
		self.capo = capo
		self.p = subprocess.Popen(['csound', '-L', 'stdin', '-odac', '-d', 'guitar2.orc'], 
			stderr=open('/dev/null', 'w'), 
			stdout=open('/dev/null', 'w'), 
			stdin=subprocess.PIPE)
		self.p.stdin.write('''
			f1 0 16384 10 1
			f3 0 16384 1 "guitar2.wav" 0 0 0
			i27 0.0 100 .2 1.52 .82 1.5 10100 5000 210 
		''')

	def playChord(self, name, strum='v', spacing=00.01):
		chord = self.chords[name]
		for s in strum:
			if s == 'v':
				self.p.stdin.write(''.join(['i3.%i %f 1 %f %i 0.5\n' % (i, spacing*i, self.tuning[i], chord[i] + self.capo) 
					for i in xrange(len(chord)) if chord[i] != '']))
			if s == '^':
				self.p.stdin.write(''.join(['i3.%i %f 1 %f %i 0.3\n' % (i, spacing*i, self.tuning[i], chord[i] + self.capo) 
					for i in reversed(xrange(len(chord))) if chord[i] != '']))
			time.sleep(0.25)

class Singer(object):
	def __init__(self, voice='Vicki', key='C'):
		self.voice = voice

	def parse(self, command):
		scale = 'C.D.EF.G.A.B'
		if command[1] in scale and command[1] != '.':
			print command
			pitch = 12.0 + 12.0*int(command[-2]) + scale.index(command[1])
			if '#' in command:
				pitch += 1
			if 'b' in command:
				pitch -= 1
			return '[[pbas ' + str(pitch) + ']]'
		
	def sing(self, words):
		words = ' '.join([w if w[0] != '[' else self.parse(w) for w in words.split()])
		self.p = subprocess.Popen(['say', '-v', self.voice, '[[pmod 0]]', words], 
			stderr=open('/dev/null', 'w'), 
			stdout=open('/dev/null', 'w'), 
			stdin=subprocess.PIPE)
		self.p.stdin.close()

	def wait(self):
		self.p.wait()

class Song(object):
	def __init__(self, lyrics, key='C', capo=0):
		self.lyrics = lyrics
		self.guitar = Guitar(capo=capo)
		self.singer = Singer(key=key)

	def play(self):
		pieces = [p for p in re.split('({[^}]*})', self.lyrics) if p.strip() != '']
		for i in xrange(len(pieces)):
			if len(pieces[i]) == 0 or pieces[i][0] != '{':
				continue
			if (i+1 < len(pieces)) and pieces[i+1][0] != '{':
				self.singer.sing(pieces[i+1])
				self.guitar.playChord(*(pieces[i][1:-1].split(',')))
				self.singer.wait()
			else:
				self.guitar.playChord(*(pieces[i][1:-1].split(',')))


Song("""
{C,...v.v.v.v.v.} [D3] Do you [E3] here [G3] meeeeeeeee, [C4] talking [B3] to [A3] {Am,v.v.v} youuuuuu? [C3] A [D3] cross, the 
{Dm7,v.v.v.v.v.} [F3] wahh [C4] teeeeeeeerr. [A3] A [C4] cross [A3] the
{G,v.v.v.v.v} [G3] Deep. [F3] Blue.
{E7,v.v.v.v.v} [E3] Oh [E4] shawwwwn, [F4] un [E4] der [D4] the 
{Am,v.v.v.v.v} oh [C4] pen [A3] skyyyyyyy. [C4] Oh [A3] myyyyyy
{Dm7,v.v.v.v} bay [G3] be [E3] I'm tuh rye
{G,v.v.v.v} [D3] ing
""").play()
