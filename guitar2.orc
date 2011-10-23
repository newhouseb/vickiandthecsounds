sr = 44100
kr = 44100
ksmps = 1
zakinit 3,3
	
instr 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Midi controlled Acoustic Guitar
; commuted waveguide synthesis
; cubic interp. for fractional delays (*deltap3*)
; Guitar loop filter from Tero Tolonen (*filter2*)
; Impulse response from Dr. Julius Smith 
; implemented by Josep M Comajuncosas / Aug´98-Sept´2000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; yet to do :
; compensation yet for the phase delay induced by the loop filter
; transient eliminator for the variable delays caused by pitchbend
; quick way to overcome this : use a pitchshifter external to the model
; also removed the interpolator for a better sound (the pitch error is ok with that chorus!)

;MIDI setup
iampn = p6; ampmidi 1;                     normalised amplitude
kmp linsegr 1, 10, 1, .04 ,0;        add some release to MIDI event

ifreq = p4 * semitone(p5); cpsmidi;                       base pitch
kfreq = p4 * semitone(p5); cpspch(p4+2); cpsmidib 2;                    continuous pitch

;kfreq tonek kfreq,10;ERROR però és genial!!!

;PERFORMANCE setup
iamp = 8000 ;                        expected maximum output amplitude
ipluck gauss .45*(1-iampn);          pluck point (at your taste)
ipluck = ipluck + .5*(1-iampn)

;STRING setup
iatt1   = .996;                      attenuation
ifco1   = -.058;                     freq dependent decay

iatt2   = .992;                      attenuation
ifco2   = -.053;                     freq dependent decay 
ichorus = 1.003;                     detuning factor (a freq. multiplier)~1

imp = .5;                            signal sent to 1st (imp=1) or 2nd (imp=0) waveguide
igc = .02;                           string vibrational plane coupling factor (must be small for stability)
imo = .5;                            signal received from 1st (imp=1) or 2nd (imp=0) waveguide


;MODEL : excitacion/IR->lowpass->comb->main waveguides->pitch shifter->sound output

; IR of the body used as the string excitation signal
anoise loscil3 1, sr/ftlen(3), 3, sr/ftlen(3),0,0,ftlen(3),0,0,ftlen(3)

; lowpass filter the excitation signal at low amplitude levels
anoise butterlp anoise,sr/3*iampn^2; tune this at your own taste

; filtering caused by plucking point
acomb delay anoise, ipluck*(1/ifreq)
anoize = anoise - acomb

; Waveguides : 2 parallel structures to simulate coupling of vertical & horizontal polarisations

idlt1 = 1/ifreq
idlt2 = idlt1/ichorus

awgout1 init 0
awgout2 init 0

atemp1 delayr 1/20
awg1 deltapn int(idlt1*kr)
alpf1 filter2 awg1, 1, 1, 1+ifco1, ifco1
awgout1   = iatt1*alpf1

atemp2 delayr 1/20
awg2 deltapn int(idlt2*kr)
alpf2 filter2 awg2, 1, 1, 1+ifco2, ifco2
awgout2   = iatt2*alpf2

ainput = anoize

ainput1 = ainput*sqrt(imp)
ainput2 = ainput*sqrt(1-imp)

delayw ainput1+awgout1*(1-igc)      ;write into delay line 1
delayw ainput2+awgout2+igc*awgout1  ;write into delay line 2

aout = sqrt(imo)*awgout1 + sqrt(1-imo)*awgout2

;pitch shifter (uncommented, included in the Csound docs.)
	kfreqsh = kfreq - ifreq;1/int(idlt1*kr)
	ain = aout
	areal, aimag hilbert ain 
	asin oscili 1, kfreqsh, 1 
	acos oscili 1, kfreqsh, 1, .25 
	amod1 = areal * acos 
	amod2 = aimag * asin 
	aout2 = (amod1 + amod2) * 0.7 

; sound output
aout = iamp*iampn*kmp*aout2
out aout
zawm aout,1
endin


;----------------------------------------------------------------------------------
; Large Room Reverb (from H.Mikelson)
;----------------------------------------------------------------------------------
       instr    27

idur   =        p3
iamp   =        p4
idecay =        p5
idense  =       p6
idense2 =       p7
ipreflt =       p8
ihpfqc  =       p9
ilpfqc  =       p10

aout91 init     0
adel01 init     0
adel11 init     0
adel51 init     0
adel52 init     0
adel91 init     0
adel92 init     0
adel93 init     0

kdclick linseg  0, .002, iamp, idur-.004, iamp, .002, 0

; Initialize
asig0  zar      1
aflt01 butterlp asig0, ipreflt             ; Pre-Filter
aflt02 butterhp .5*aout91, ihpfqc          ; Feed-Back Filter
aflt03 butterlp aflt02, ilpfqc             ; Feed-Back Filter
asum01  =       aflt01+.5*idense2*aflt03   ; Initial Mix

; All-Pass 1
asub01  =       adel01-.3*idense*asum01              ; Feedforward
adel01  delay   asum01+.3*idense*asub01,.008*idecay  ; Feedback

; All-Pass 2
asub11  =       adel11-.3*idense*asub01              ; Feedforward
adel11  delay   asub01+.3*idense*asub11,.012*idecay  ; Feedback

adel21  delay   asub11, .004*idecay                   ; Delay 1
adel41  delay   adel21, .017*idecay                   ; Delay 2

; Single Nested All-Pass
asum51  =       adel52-.25*adel51*idense              ; Inner Feedforward
aout51  =       asum51-.50*adel41*idense              ; Outer Feedforward
adel51  delay   adel41+.50*aout51*idense, .025*idecay ; Outer Feedback
adel52  delay   adel51+.25*asum51*idense, .062*idecay ; Inner Feedback

adel61  delay   aout51, .031*idecay                   ; Delay 3
adel81  delay   adel61, .003*idecay                   ; Delay 4

; Double Nested All-Pass
asum91  =       adel92-.25*adel91*idense              ; First  Inner Feedforward
asum92  =       adel93-.25*asum91*idense              ; Second Inner Feedforward
aout91  =       asum92-.50*adel81*idense              ; Outer Feedforward
adel91  delay   adel81+.50*aout91*idense, .120*idecay ; Outer Feedback
adel92  delay   adel91+.25*asum91*idense, .076*idecay ; First  Inner Feedback
adel93  delay   asum91+.25*asum92*idense, .030*idecay ; Second Inner Feedback

aout    =       .8*aout91+.8*adel61+1.5*adel21 ; Combine outputs

out aout*kdclick
zacl 0,2
        endin
