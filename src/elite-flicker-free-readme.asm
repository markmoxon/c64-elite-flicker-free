; ******************************************************************************
;
; COMMODORE 64 FLICKER-FREE ELITE README
;
; BBC Master Elite was written by Ian Bell and David Braben and is copyright
; Acornsoft 1986
;
; The code on this site has been reconstructed from a disassembly of the version
; released on Ian Bell's personal website at http://www.elitehomepage.org/
;
; The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
; in the documentation are entirely my fault
;
; The terminology and notations used in this commentary are explained at
; https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
;
; The deep dive articles referred to in this commentary can be found at
; https://www.bbcelite.com/deep_dives
;
; ******************************************************************************

MACRO CAP x
 EQUB x + 128
ENDMACRO

.readmeC64

 EQUB 13
 EQUS "---------------------------------------"
 EQUB 13
 CAP 'F'
 EQUS "LICKER-FREE "
 CAP 'C'
 EQUS "OMMODORE 64 "
 CAP 'E'
 EQUS "LITE"
 EQUB 13
 EQUB 13
 CAP 'C'
 EQUS "ONTAINS THE FLICKER-FREE SHIP DRAWING "
 EQUB 13
 EQUS "ROUTINES FROM THE "
 CAP 'B'
 CAP 'B'
 CAP 'C'
 EQUS " "
 CAP 'M'
 EQUS "ASTER VERSION,"
 EQUB 13
 EQUS "BACKPORTED BY "
 CAP 'M'
 EQUS "ARK "
 CAP 'M'
 EQUS "OXON"
 EQUB 13
 EQUB 13
 CAP 'C'
 EQUS "ONTAINS FLICKER-FREE PLANET DRAWING "
 EQUB 13
 EQUS "ROUTINES BY "
 CAP 'M'
 EQUS "ARK "
 CAP 'M'
 EQUS "OXON"
 EQUB 13
 EQUB 13
 CAP 'B'
 EQUS "ASED ON THE "
 CAP 'F'
 EQUS "IREBIRD RELEASE OF "
 CAP 'E'
 EQUS "LITE"
 EQUB 13
 CAP 'B'
 EQUS "Y "
 CAP 'I'
 EQUS "AN "
 CAP 'B'
 EQUS "ELL AND "
 CAP 'D'
 EQUS "AVID "
 CAP 'B'
 EQUS "RABEN"
 EQUB 13
 CAP 'C'
 EQUS "OPYRIGHT (C) "
 CAP 'D'
 EQUS "."
 CAP 'B'
 EQUS "RABEN AND "
 CAP 'I'
 EQUS "."
 CAP 'B'
 EQUS "ELL 1985"
 EQUB 13
 EQUB 13
 CAP 'S'
 EQUS "EE WWW.BBCELITE.COM FOR DETAILS"
 EQUB 13
 EQUB 13
 CAP 'B'
 EQUS "UILD: ", TIME$("%F %T")
 EQUB 13
 EQUS "---------------------------------------"
 EQUB 13

 SAVE "README64.txt", readmeC64, P%
