# Generic Makefile for C, C++, Java, and LaTeX code
# See the NOTES section at the bottum of this file for documentation
# khellman@mines.edu

# DEFAULT DEFS

# bash 4.0.28 on debian testing has turned pedantic when invoked as
# sh.  I don't think I could write a pure sh script anymore ... :^(
SHELL:=$(word 2,$(shell whereis -b bash))
export SHELL

###############################################################################
# Yes there is a difference between CPPFLAGS, CFLAGS
# CXXFLAGS:
#   CPPFLAGS are for the *precompiler*, things like -I and -D
#   CFLAGS for common options of the C and C++  compiler, so don't include cruft like -fno-exceptions
#   CXXFLAGS are for the C++ compiler, this is where you put stuff like -fno-exceptions
# In most cases CFLAGS can be provided to both your C and C++ compiler.
# CCVERSION can be like -4.1 to specify a particular toolchain...  typically
# CCVERSION is empty.
#
# yes, this should be explicit because gmake has defaults we don't want
ifneq ($(word 2,$(shell whereis -b cc)),)
CC=cc${CCVERSION}
CXX=c++${CCVERSION}
else
ifneq ($(word 2,$(shell whereis -b gcc)),)
CC=gcc${CCVERSION}
CXX=g++${CCVERSION}
GNUCFLAGS?=-D_GNU_SOURCE -D__USE_GNU
endif
endif # cc or gcc?
ifneq ($(wildcard *.cxx *.c++ *.cpp *.cc),)
LD=${CXX}
else
ifneq ($(wildcard *.c),)
LD=${CC}
endif  # C exists
endif  # C++ source exists
AR?=ar

# There are otherways to accomplish the below, but despite it's kludgyness, it
# is more readable than having lots of ifeq() or ifneq() statements all over the 
# place.  When you want more functionality or flexibility than is provided here, 
# then wrap the *include* of this file with another project specific one.
# NOTE:  the goal here is to provide decent defaults AND to keep project
#        specific code OUT of this file (so you can update this by simple copying).
ifneq (${RELEASE},)
CPPFLAGS?=-DNDEBUG ${GNUCFLAGS}
CFLAGS?=-Wall -O2
CXXFLAGS?=${CFLAGS}
else
CPPFLAGS?=${GNUCFLAGS}
CFLAGS?=-Wall -g
CXXFLAGS?=${CFLAGS}
endif
CXXFLAGS:=$(filter-out -std=c99,${CXXFLAGS})
# End of the kludge

# these are linking flags provided for your applications
LDFLAGS?=
# flags for building your shared libraries
SOFLAGS?=-shared
# flags for updating a static archive 
ARFLAGS?=crsu
###############################################################################

###############################################################################
# your lex flags
LEX?=lex
LEXFLAGS+=
###############################################################################

###############################################################################
# your yacc flags
YACC?=yacc
YACCFLAGS+=
###############################################################################

###############################################################################
# your java flags
JAVAC?=javac
JAVACFLAGS+=
###############################################################################

###############################################################################
# your latex flags
# if you set PDFLATEX in your Project.make file, then the traditional
#   tex->dvi->ps->pdf chain will be replaced with tex->pdf using ${PDFLATEX}
#PDFLATEX?=pdflatex

# use pslatex if we can find it
# --- BIG FAT WARNING ---
# pslatex does not play nice with dot generated eps files, use latex for these
# builds instead
# --- BIG FAT WARNING ---
LATEX?=$(shell which pslatex |head -1)
#LATEX=latex
# otherwise just use latex
LATEX?=latex

#LATEXFLAGS+=-shell-escape
LATEXFLAGS+=-interaction=nonstopmode
LATEXFLAGS+=-file-line-error 

DVIPS?=dvips
DVIPSFLAGS?=-t letter
PS2PDF?=ps2pdf
PDF2PS?=pdf2ps
EPSTOPDF?=epstopdf
PDFTOPS?=pdftops
BIBTEX?=bibtex --min-crossref 999999
METAPOST?=mpost
METAPOSTFLAGS+=-interaction=nonstopmode
METAPOSTFLAGS+=-file-line-error
GNUPLOT?=gnuplot
CONVERT?=convert
DIA?=dia
FIG2DEV?=fig2dev -K
FIG2MPDF?=$(word 2,$(shell whereis -b fig2mpdf)) 
ifeq (${PDFLATEX},)
figps=eps
DVIEXT=dvi
figtarget=ps
else
figps=pdf
DVIEXT=pdf
figtarget=pdf
endif
###############################################################################

###############################################################################
# your python flags
ifeq (${PYCHECKER},)
PYCHECKER=pychecker -\# 99999 --quiet --only --no-varargsused --no-argsused 
endif
###############################################################################

###############################################################################
# utility defs
RM?=rm -f
###############################################################################


# it is always important to have your default rule at the top of the Makefile, so
# we do this here.  Search for the word PHONY for more info on the 'double-colon'
# mode for targets.
all::

# some critical macros...
srcdep=$(strip $(patsubst %,.%.d,${1}))
srcobjects=$(strip $(foreach EXT,c cxx cpp cc C CC,$(patsubst %.${EXT},%.o,$(filter %.${EXT},${1}))))
SET_CPPFLAGS=$(eval $(call set_cppflags_srcdep,${1},${2})) $(eval $(call set_cppflags_srcobjects,${1},${2}))
define set_cppflags_srcdep
$(call srcdep,${1}): CPPFLAGS:=${2}
endef
define set_cppflags_srcobjects
$(call srcobjects,${1}): CPPFLAGS:=${2}
endef


# all of your project specific stuff should be included in a Project.mak
# file in the same directory as this Makefile; we display a friendly error
# message if one cannot be found.
PROJECT_MAK_NAME?=Project.mak
ifeq (${SKIP_PROJECT_MAK},)
ifneq ($(wildcard ${PROJECT_MAK_NAME}),${PROJECT_MAK_NAME})
$(warning Create a '${PROJECT_MAK_NAME}' file to use this Makefile template. )
$(warning See the Project.mak alongside the (true) Makefile location, )
$(warning or the SimplistProject.mak file for an example Project.mak file. )
$(error ERROR:  no ${PROJECT_MAK_NAME} found)
endif
endif
-include ./${PROJECT_MAK_NAME}
# these lines automatically determine the source files in your directory.  if you add
# C++ extentions, you will need to add a %.o build rule and adjust the realclean rule
# as well
CSOURCE?=$(wildcard *.c)
CXXSOURCE?=$(wildcard *.cxx *.cpp *.cc *.c++)
JAVASOURCE?=$(wildcard *.java)
LATEXSOURCE?=$(filter-out %_latex.tex %_pstricks.tex mpxerr.tex,$(wildcard *.tex))
BIBTEXSOURCE?=$(wildcard *.bib)
PYSOURCE?=$(wildcard *.py)
RSTSOURCE?=$(wildcard *.rst)
LEXSOURCE?=$(wildcard *.l)
YACCSOURCE?=$(wildcard *.y)

# you can optionally filter-out files you don't want processes.
# provide a variables called NOTCSOURCE, NOTCXXSOURCE, NOTJAVASOURCE
# in your Project.mak file, ie:
#   NOTCSOURCE=notme.c
#   NOTCXXSOURCE=notme.cxx
#   NOTJAVASOURCE=notme.java
#   NOTRSTSOURCE=notme.rst
NOTLATEXSOURCE?=$(patsubst %.gp,%_latex.tex,$(wildcard *.gp)) $(patsubst %.fig,%_latex.tex,$(wildcard *.fig)) 

CSOURCE:=$(filter-out ${NOTCSOURCE},${CSOURCE})
CXXSOURCE:=$(filter-out ${NOTCXXSOURCE},${CXXSOURCE})
JAVASOURCE:=$(filter-out ${NOTJAVASOURCE},${JAVASOURCE})
LATEXSOURCE:=$(filter-out ${NOTLATEXSOURCE},${LATEXSOURCE})
BIBTEXSOURCE:=$(filter-out ${NOTBIBTEXSOURCE},${BIBTEXSOURCE})
PYSOURCE:=$(filter-out ${NOTPYSOURCE},${PYSOURCE})
RSTSOURCE:=$(filter-out ${NOTRSTSOURCE},${RSTSOURCE})
LEXSOURCE:=$(filter-out ${NOTLEXSOURCE},${LEXSOURCE})
YACCSOURCE:=$(filter-out ${NOTYACCSOURCE},${YACCSOURCE})

# this step creates the OBJECTS or CLASSES variables automatically
# from the *SOURCE variables
OBJECTS?=$(call srcobjects,${CSOURCE} ${CXXSOURCE} $(patsubst %.l,%.yy.c,${LEXSOURCE}) $(patsubst %.y,%.tab.c,${YACCSOURCE})) 
CLASSES?=$(patsubst %.java,%.class,${JAVASOURCE})

ifeq (${PDFLATEX},)
TARGET_PS?=$(patsubst %.tex,%.ps,${LATEXSOURCE})
TARGET_DVI?=$(patsubst %.tex,%.${DVIEXT},${LATEXSOURCE})
LATEXTARGET?=${TARGET_PS}
else
TARGET_PDF?=$(patsubst %.tex,%.pdf,${LATEXSOURCE})
TARGET_DVI?=${TARGET_PDF}
LATEXTARGET?=${TARGET_PDF}
endif
# needed for external refs
LATEXAUXTARGET=$(patsubst %.tex,%.aux,${LATEXSOURCE})
LATEXSNMTARGET=$(patsubst %.tex,%.snm,${LATEXSOURCE})
.PRECIOUS: ${LATEXAUXTARGET} ${LATEXSNMTARGET}
# all those latex ancilliary files (includes makeindex, ... )
# NOTE:  dvi, ps, and pdf are placed into LATEXCLEAN directly, ancilliary
# source name independent files are placed into LATEXCLEAN_
LATEXCLEANEXTS=aux snm dvi ps pdf glo gls idx ilg toc lof lot log bbl blg -blx.bib .run.xml brf vrb out nav lox
ifeq (${PDFLATEX},)
LATEXCLEANEXTS:=${LATEXCLEANEXTS} dvi
endif
latex_sideeffect_files=$(foreach ext,${LATEXCLEANEXTS},$(patsubst %.tex,%.${ext},$(filter %.tex,${1}))) \
                        $(foreach ext,${LATEXCLEANEXTS},$(patsubst %,%.${ext},$(filter-out %.tex,${1}))) 
ifneq (${LATEXSOURCE},)
LATEXCLEAN_+=missfont.log
LATEXCLEAN_+=texput.log
endif

# all and clean are phony targets, they should be built even if there
# is a file named
# 'all' or 'clean' in your directory
# you can make a rule dependent on FORCE to ensure it is always out of date
.PHONY: all clean realclean 
# we also make these rules 'double-colon' rules, this allows you to chain different
# commands onto the rule.  Every 'all' and 'clean' target in this Makefile must
# be specified with a ::.
# the advantage to using double colon rules is that, specifically for clean, you can keep the
# logic associated with cleaning up one target *where the target rule is*.  Suppose you decide
# to autogenerate some header files with perl.  You add the appropriate targets *and* you add the 
# 'clean' double-colon rule in the same location of the target.
# - This lets you comment them both on one place
# - This keeps the logic all in one place.  You won't go to your (single-colon) 'clean' rule and
#   wonder why in the $#%#@^ are these perl files being cleaned up?
# - This keeps all the logic in one place.  So when you change the perl rules to python, you will
#   *see* the clean lines that need to be changed as well.  You won't forget them, and you won't
#   have to go looking for them.
# The same type of logic goes for 'all' as well.
clean:: clean-python
realclean:: clean
# No, no, no.  Don't make FORCE a .PHONY, this actually makes it, um, unforced.
FORCE::

ifeq (${NOAUTODEPS},)
###############################################################################
# rule for generating dependency files automagically - (stolen from make info).  The sed statement turns
# x.o: x.c x.h into 
# x.o x.d: x.c x.h 
# so make will rebuild dependency files when needed
AUTODEPS=$(call srcdep,${CSOURCE} ${CXXSOURCE}) 
ifeq ($(filter clean% %clean,${MAKECMDGOALS}),)
# do not include dependencies when we are cleaning
-include ${AUTODEPS} /dev/null
endif
# we can use one rule for both C and C++ files, capability that may be specific to GNU gcc, I dunno.
.%.d: % 
	@set -e; \
	${CC} -M ${CPPFLAGS} $< | sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	test -s $@ || rm -f $@

clean::
	${RM} ${AUTODEPS}
	
realclean::
	${RM} .*.{c,cxx,cpp,cc,C,CC}.d
###############################################################################
endif	

###############################################################################
# c/c++ build rules
.PHONY: objects
objects: ${OBJECTS}

%.o: %.c
	${CC} ${CPPFLAGS} ${CFLAGS} -c -o $(@F) $<

%.o: %.cxx
	${CXX} ${CPPFLAGS} ${CXXFLAGS} -c -o $(@F) $<

%.o: %.cpp
	${CXX} ${CPPFLAGS} ${CXXFLAGS} -c -o $(@F) $<

%.o: %.cc
	${CXX} ${CPPFLAGS} ${CXXFLAGS} -c -o $(@F) $<

%.o: %.C
	${CXX} ${CPPFLAGS} ${CXXFLAGS} -c -o $(@F) $<

%.o: %.CC
	${CXX} ${CPPFLAGS} ${CXXFLAGS} -c -o $(@F) $<

clean::
	${RM} ${OBJECTS}

realclean::
	${RM} *.o
###############################################################################

###############################################################################
# static archives
%.a:
	${AR} ${ARFLAGS} $(@F) $^

clean::
	${RM} ${TARGET_A}
	
realclean::
	${RM} *.a
###############################################################################

###############################################################################
# shared libraries
%.so:
	${LD} ${SOFLAGS} -o $(@F) $^ ${SOLIBS} 

clean::
	${RM} ${TARGET_SO}

realclean::
	${RM} *.so
###############################################################################

###############################################################################
# C/C++ applictions to be built
${TARGET_APP}: 
	${LD} ${LDFLAGS} -o $(@F) $^ ${LIBS} 

clean::
	${RM} ${TARGET_APP}
###############################################################################

###############################################################################
# lex rules
%.yy.c: %.l
	${LEX} -t ${LEXFLAGS} $< >$@

clean::
	${RM} $(patsubst %.l,%.yy.c,${LEXSOURCE})
###############################################################################

###############################################################################
# yacc rules
%.tab.c %.tab.h: %.y
	${YACC} -o $@ ${YACCFLAGS} $< 
clean::
	${RM} $(patsubst %.y,%.tab.[ch],${YACCSOURCE})
###############################################################################

###############################################################################
# java builds
%.class: %.java
	${JAVAC} ${JAVACFLAGS} $^

clean::
	${RM} ${CLASSES}

realclean::
	${RM} *.class
###############################################################################

###############################################################################
# latex builds

%.bbl: %.bib
	${BIBTEX} $(patsubst %.bib,%,$<)

ifeq (${PDFLATEX},)
# tex->dvi->ps->pdf
# Make the dvi and ps files precious, so that we don't waste time rebuilding
.PRECIOUS: $(patsubst %.tex,%.dvi,${LATEXSOURCE})
.PRECIOUS: $(patsubst %.tex,%.ps,${LATEXSOURCE})

###
# source specific side effect files should be remove before each build,
# otherwise pslatex/latex has flaky build behaviour causing red-herrings
# looking for document syntax issues which don't really exist.
###
%.${DVIEXT}: %.tex
	${RM} $(call latex_sideeffect_files,$<) ${LATEXCLEAN_} ; \
	set -e ; \
	TFILE="$(patsubst %.tex,%,$<)" ; \
	AUX="$(patsubst %.tex,%.aux,$<)" ; \
	BBL="$(patsubst %.tex,%.bib,$<)" ; \
	PP=0 ; \
	echo -e >&2  "\n***\nRUNNING LATEX 1\n***\n" ; \
	${LATEX} ${LATEXFLAGS} $< ; \
	if test -n "$${LATEX_ONE_RUN}" ; then exit 0; fi ; \
	if grep -E -e '\\(bibdata|cite|citation)' $${AUX} >/dev/null ; then \
		${BIBTEX} ${BIBTEXFLAGS} $${TFILE} ; PP=1; fi ; \
	if test $${PP} -eq 0 && grep '\\newlabel{' $${AUX} >/dev/null ; then \
		PP=1; fi ; \
	echo -e >&2  "\n***\nRUNNING LATEX 2\n***\n" ; \
	${LATEX} ${LATEXFLAGS} $< ; \
	if test $${PP} -eq 1 ; then \
		echo -e >&2  "\n***\nRUNNING LATEX 3\n***\n" ; \
		${LATEX} ${LATEXFLAGS} $< ; \
		fi ; \
	exit 0 ;

${TARGET_DVI}: %.${DVIEXT} : %.tex
	${RM} $(call latex_sideeffect_files,$<) ${LATEXCLEAN_} ; \
	set -e ; \
	TFILE="$(patsubst %.tex,%,$<)" ; \
	AUX="$(patsubst %.tex,%.aux,$<)" ; \
	BBL="$(patsubst %.tex,%.bib,$<)" ; \
	PP=0 ; \
	echo -e >&2  "\n***\nRUNNING LATEX 1\n***\n" ; \
	${LATEX} ${LATEXFLAGS} $< ; \
	if test -n "$${LATEX_ONE_RUN}" ; then exit 0; fi ; \
	if grep -E -e '\\(bibdata|cite|citation)' $${AUX} >/dev/null ; then \
		${BIBTEX} ${BIBTEXFLAGS} $${TFILE} ; PP=1; fi ; \
	if test $${PP} -eq 0 && grep '\\newlabel{' $${AUX} >/dev/null ; then \
		PP=1; fi ; \
	echo -e >&2  "\n***\nRUNNING LATEX 2\n***\n" ; \
	${LATEX} ${LATEXFLAGS} $< ; \
	if test $${PP} -eq 1 ; then \
		echo -e >&2  "\n***\nRUNNING LATEX 3\n***\n" ; \
		${LATEX} ${LATEXFLAGS} $< ; \
		fi ; \
	exit 0 ;

%.ps:  %.dvi
	${DVIPS} ${DVIPSFLAGS} -o $@ $<

$(patsubst %.tex,%.pdf,${LATEXSOURCE}):  %.pdf : %.ps
	${PS2PDF} ${P2PDFFLAGS} $< $@

# support for bounding box - you must still list the .eps.bb as a dependency of the 
# LaTeX document that embeds it
EPS_BB_GZIPSOURCE?=$(wildcard *.eps.gz)
#ifneq (${EPS_BB_GZIPSOURCE},)
%.eps.bb : %.eps.gz
	gunzip -c $< |gs -q -sNOPAUSE -sDEVICE=bbox -sBATCH /dev/stdin 2>$@
%.eps.bb : %.eps
	gs -q -sNOPAUSE -sDEVICE=bbox -sBATCH /dev/stdin 2>$@ < $< 
%.eps : %.eps.gz
	gunzip -c $< >$@
#endif
else
# tex->pdf via pdflatex
PDFLATEXFLAGS?=${LATEXFLAGS}
${TARGET_PDF}: %.pdf : %.tex
	${RM} $(call latex_sideeffect_files,$<) ${LATEXCLEAN_} ; \
	set -e ; \
	TFILE="$(patsubst %.tex,%,$<)" ; \
	AUX="$(patsubst %.tex,%.aux,$<)" ; \
	BBL="$(patsubst %.tex,%.bib,$<)" ; \
	PP=0 ; \
	echo -e >&2  "\n***\nRUNNING PDFLATEX 1\n***\n" ; \
	${PDFLATEX} ${PDFLATEXFLAGS} $< ; \
	if test -n "$${LATEX_ONE_RUN}" ; then exit 0; fi ; \
	if grep '\\bibdata{' $${AUX} >/dev/null || grep '\\cite' $${AUX} >/dev/null ; then \
		${BIBTEX} ${BIBTEXFLAGS} $${TFILE} ; PP=1; fi ; \
	if test $${PP} -eq 0 && grep '\\newlabel{' $${AUX} >/dev/null ; then \
		PP=1; fi ; \
	echo -e >&2  "\n***\nRUNNING PDFLATEX 2\n***\n" ; \
	${PDFLATEX} ${PDFLATEXFLAGS} $< ; \
	if test $${PP} -eq 1 ; then \
		echo -e >&2  "\n***\nRUNNING PDFLATEX 3\n***\n" ; \
		${PDFLATEX} ${PDFLATEXFLAGS} $< ; \
		fi ; \
	exit 0 ;

###
# this line occasionally requires independent cleans to be performed
# (you can't do
#   $ make PDFLATEX=pdflatex clean all
#  you must do
#   $ make PDFLATEX=pdflatex clean ; make PDFLATEX=pdflatex all
# )
# we need a specialized conversion from eps to pdf until gnuplot can do pdf+tex
###
$(patsubst %.tex,%.ps,${LATEXSOURCE}):  %.ps : %.pdf
	${PDF2PS} ${PDF2PSFLAGS} $< $@

# convert compressed eps files to PDFs
EPS_BB_GZIPSOURCE?=$(wildcard *.eps.gz)
ifneq (${EPS_BB_GZIPSOURCE},)
%.pdf : %.eps.gz
	gunzip -c $< | ${EPSTOPDF} ${EPSTOPDFFLAGS} --filter >$@

endif
endif
LATEXCLEAN+=$(patsubst %.eps.gz,%.eps.bb,${EPS_BB_GZIPSOURCE})
LATEXCLEAN+=$(patsubst %.eps.gz,%.pdf,${EPS_BB_GZIPSOURCE})

pdfs:: $(patsubst %.tex,%.pdf,${LATEXSOURCE})
pss:: $(patsubst %.tex,%.ps,${LATEXSOURCE})

clean-latex::
	${RM} $(call latex_sideeffect_files,${LATEXSOURCE})
	${RM} ${LATEXCLEAN_}
	${RM} ${LATEXCLEAN} 

clean:: clean-latex


GPSOURCE?=$(wildcard *.gp)
GNUPLOTCLEAN+=$(patsubst %.gp,%_latex.tex,${GPSOURCE})
GNUPLOTCLEAN+=$(patsubst %.gp,%_latex.pdf,${GPSOURCE})
GNUPLOTCLEAN+=$(patsubst %.gp,%_latex.eps,${GPSOURCE})
GNUPLOTCLEAN+=$(patsubst %.gp,%_pstricks.tex,${GPSOURCE})
#GNUPLOTCLEAN+=$(patsubst %.gp,%_gp.fig,${GPSOURCE})
GNUPLOTCLEAN+=$(patsubst %.gp,%_gp_latex.*,${GPSOURCE})

# in inches
GP_SIZEX?=4
GP_SIZEY?=3

###
# gppress is in Keiths ~/sbox/myhome/bin, should someone need it...
###

## gnuplot to tex + eps rule (gnuplot produces two files, eps and tex, on one invokation)
%_latex.tex %_latex.eps: %.gp 
	gppress --target latex --size ${GP_SIZEX},${GP_SIZEY} --sed 's/$$/_latex/' ${GPPRESSFLAGS} $<

%_pstricks.tex: %.gp 
	gppress --target pstricks --sed 's/$$/_pstricks/' ${GPPRESSFLAGS} $<

%_gp.fig:  %.gp
	gppress --target fig --size ${GP_SIZEX},${GP_SIZEY} --sed 's/$$/_gp/' ${GPPRESSFLAGS} $<

GP_IMAGE_WIDTH?=400
GP_IMAGE_HEIGHT?=300

%.svg: %.gp
	gppress --target svg --size ${GP_IMAGE_WIDTH},${GP_IMAGE_HEIGHT} ${GPPRESSFLAGS} $<
GNUPLOTCLEAN+=$(patsubst %.gp,%.svg,${GPSOURCE})

%.png: %.gp
	gppress --target png --size ${GP_IMAGE_WIDTH},${GP_IMAGE_HEIGHT} ${GPPRESSFLAGS} $<
GNUPLOTCLEAN+=$(patsubst %.gp,%.png,${GPSOURCE})

%.eps: %.gp
	gppress --target eps --size ${GP_SIZEX},${GP_SIZEY} ${GPPRESSFLAGS} $<
GNUPLOTCLEAN+=$(patsubst %.gp,%.eps,${GPSOURCE})

%.pdf: %.gp
	gppress --target pdf --size ${GP_SIZEX},${GP_SIZEY} ${GPPRESSFLAGS} $<
GNUPLOTCLEAN+=$(patsubst %.gp,%.pdf,${GPSOURCE})

clean:: clean-gnuplot
clean-gnuplot:
	${RM} ${GNUPLOTCLEAN}


###
# dvi2svgm utility - the awkward %_<utility>.ext rule makes it easy to 
# select a specific construction rules
###
DVISVGMFLAGS?=--no-fonts
%_dvi2svgm.svg: %.dvi
	dvisvgm ${DVISVGMFLAGS} $< $@

ifneq (${DVISVGMRULES},)
%.svg: %.dvi
	dvisvgm ${DVISVGMFLAGS} $< $@
endif



###
# The dia support has fallen way behind since I've switched completely to xfig.
# These rules can be easily fixed up when the need arises.
### dia to all sorts of targets
#%.eps:  %.dia
#	${DIA} -t eps ${DIAFLAGS} -e $@ $<
#
#%.svg:  %.dia
#	${DIA} -t svg ${DIAFLAGS} -e $@ $<
#
#%.png:  %.dia
#	${DIA} -t png ${DIAFLAGS} -e $@ $<
#
#%.tex:  %.dia
#	${DIA} -t tex ${DIAFLAGS} -e $@ $<
#
#%.fig:  %.dia
#	${DIA} -t fig ${DIAFLAGS} -e $@ $<
#
#%.pdf:  %.dia
#	${DIA} -t pdf ${DIAFLAGS} -e $@ $<


# xfig files to latex
# NOTE I provide two separate rules so that FIG2DEVFLAGS can be tweaked for
# both the tex and ps file separately!
# HOWEVER, you *can* just specify FIG2DEVFLAGS for the .tex target.  Since
# it depends on .ps, the .ps will inherit the FIG2DEVFLAGS for .tex unless
# explicitly specified in the Project.mak file
FIGSOURCE?=$(filter-out %_gp.fig,$(wildcard *.fig))

###
# beware, with -F engaged, don't try to scale fonts using the fig2dev -s switch.
# you'll get strange latex compile errors around NFSS statements.  The figs
# that don't have -s will define a 5 argument latex command (what you usually want, see
# the man page -F info for fig2dev), while the -s figs will have a 2 argument command.
# Ugh.
###
FIG2DEV_FONTFLAG=-F
XFIGCLEAN+=$(patsubst %.fig,%_latex.*,${FIGSOURCE})
%_latex.tex: %.fig %_latex.${figps}
	psf="$(patsubst %.tex,%.${figps},$@)" ; \
	${FIG2DEV} -L ${figtarget}tex_t -p $${psf} ${FIG2DEV_FONTFLAG} ${FIG2DEVFLAGS} $(if ${FIG2DEVSOURCE},${FIG2DEVSOURCE},$<) $@ 

.PRECIOUS: $(patsubst %.fig,%_latex.eps,${FIGSOURCE})
%_latex.${figps}: %.fig
	${FIG2DEV} -L ${figtarget}tex ${FIG2DEVFLAGS} $(if ${FIG2DEVSOURCE},${FIG2DEVSOURCE},$<) $@


XFIGCLEAN+=$(patsubst %.fig,%.svg,${FIGSOURCE})
%.svg: %.fig
	${FIG2DEV} -L svg ${FIG2DEVFLAGS} $(if ${FIG2DEVSOURCE},${FIG2DEVSOURCE},$<) $@
	

XFIGCLEAN+=$(patsubst %.fig,%.eps,${FIGSOURCE})
XFIGCLEAN+=$(patsubst %.fig,%.pdf,${FIGSOURCE})
ifneq (${FIG2MPDF},)
ifeq (${PDFLATEX},)
%.eps: %.fig
	${FIG2MPDF} -e ${FIG2MPDFFLAGS} $< 

%.pdf: %.fig
	${FIG2MPDF} ${FIG2MPDFFLAGS} $<
else
%.pdf: %.fig
	${FIG2MPDF} ${FIG2MPDFFLAGS} $<
endif
endif

.PHONY: clean-xfig
clean:: clean-xfig
clean-xfig:
	${RM} ${XFIGCLEAN}

###############################################################################



###############################################################################
# inkscape rules
INKSCAPE?=inkscape
INKSCAPESOURCE?=$(filter-out %_dvi2svgm.svg,$(wildcard *.svg))

%.pdf: %.svg
	${INKSCAPE} ${INKSCAPEFLAGS} --export-type=pdf --export-filename=$@ --export-overwrite $<

%.eps: %.svg
	${INKSCAPE} --export-ps-level 3 ${INKSCAPEFLAGS} --export-type=eps --export-filename=$@ --export-overwrite $<

%.ps: %.svg
	${INKSCAPE} -f=$< --export-ps-level 3 ${INKSCAPEFLAGS} --export-ps=$@ 

# doesn't work all that great :(
%_latex.eps: %.svg
	${INKSCAPE} -f=$< --export-latex --export-ps-level 3 ${INKSCAPEFLAGS} --export-filename=$@ 
	mv $*_latex.eps_tex $*_latex.tex

%_latex.tex: %.svg
	${MAKE} $*_latex.eps

.PHONY: clean-inkscape
clean:: clean-inkscape
clean-inkscape:
	${RM} $(patsubst %.svg,%.eps,${INKSCAPESOURCE})
	${RM} $(patsubst %.svg,%.ps,${INKSCAPESOURCE})
	${RM} $(patsubst %.svg,%.pdf,${INKSCAPESOURCE})
	${RM} $(patsubst %.svg,%_latex.eps,${INKSCAPESOURCE}) $(patsubst %.svg,%_latex.tex,${INKSCAPESOURCE})

###############################################################################




###############################################################################
# MetaPost rules
METAPOSTSOURCE?=$(filter-out %_gp.mp,$(wildcard *.mp))

###
# beware, with -F engaged, don't try to scale fonts using the fig2dev -s switch.
# you'll get strange latex compile errors around NFSS statements.  The figs
# that don't have -s will define a 5 argument latex command (what you usually want, see
# the man page -F info for fig2dev), while the -s figs will have a 2 argument command.
# Ugh.
###
METAPOSTCLEAN+=$(patsubst %.mp,%.[0-9]*,${MPSOURCE})

METAPOSTMAX?=8
METAPOSTEXTENSIONS=$(shell for ((i=0;i<${METAPOSTMAX};i++)); do echo -n "$${i} "; done)
$(foreach ext,${METAPOSTEXTENSIONS},%.${ext}) : %.mp 
	${METAPOST} ${METAPOSTFLAGS} $< 

clean:: clean-metapost
METAPOSTCLEANEXT=$(shell echo -n "{"; c=''; for ((i=0;i<${METAPOSTMAX};i++)); do echo -n "$${c}$${i}"; c=','; done; echo -n "}")
METAPOSTCLEANFILES=$(patsubst %.mp,%.${METAPOSTCLEANEXT},${METAPOSTSOURCE}) 
clean-metapost:
	${RM} ${METAPOSTCLEANFILES} 
	${RM} $(patsubst %.mp,%.mpx,${METAPOSTSOURCE})
	${RM} $(patsubst %.mp,%.log,${METAPOSTSOURCE})
	${RM} ^^@
	${RM} mpxerr.tex
		
###############################################################################

###############################################################################
# python rules
ifneq (${PYSOURCE},)
.PHONY: pychecker __main__
pychecker: FORCE
	${PYCHECKER} ${PYSOURCE} 

lint:: pychecker

# run modules __main__ code
__main__: FORCE
	set -e ; for p in ${PYSOURCE} ; do python $${p} ; done
endif

clean-python:
	${RM} *.pyc
	${RM} -r __pycache__

clean:: clean-python

###############################################################################


###############################################################################
# utility rules
show-%: FORCE
	@echo "$(patsubst show-%,%,$@)=<${$(patsubst show-%,%,$@)}>"
###############################################################################

###############################################################################
# graphvis rules (http://www.graphvis.org/)
GRAPHVIS?=dot
#GRAPHVISFLAGS?=
GRAPHVIS_SOURCE?=$(wildcard *.gv)
GRAPHVIS_TARGETS?= $(patsubst %.gv,%.pdf,${GRAPHVIS_SOURCE})      $(patsubst %.gv,%_graphvis.pdf,${GRAPHVIS_SOURCE})
GRAPHVIS_PS_TARGETS?= $(patsubst %.gv,%.ps,${GRAPHVIS_SOURCE})    $(patsubst %.gv,%_graphvis.ps,${GRAPHVIS_SOURCE})
GRAPHVIS_PNG_TARGETS?= $(patsubst %.gv,%.png,${GRAPHVIS_SOURCE})  $(patsubst %.gv,%_graphvis.png,${GRAPHVIS_SOURCE})
GRAPHVIS_EPS_TARGETS?= $(patsubst %.gv,%.eps,${GRAPHVIS_SOURCE})  $(patsubst %.gv,%_graphvis.eps,${GRAPHVIS_SOURCE})
GRAPHVIS_JPG_TARGETS?= $(patsubst %.gv,%.jpg,${GRAPHVIS_SOURCE})  $(patsubst %.gv,%_graphvis.jpg,${GRAPHVIS_SOURCE})
GRAPHVIS_ALL_TARGETS?=${GRAPHVIS_TARGETS} ${GRAPHVIS_PS_TARGETS} ${GRAPHVIS_PNG_TARGETS} ${GRAPHVIS_EPS_TARGETS} ${GRAPHVIS_JPG_TARGETS}

ifneq (${GRAPHVIS_FLAGS},)
$(error GRAPHVIS_FLAGS should be GRAPHVISFLAGS)
endif

%.pdf: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T pdf $<  >$@

%_graphvis.pdf: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T pdf $<  >$@

%.ps: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T ps $<  >$@

%_graphvis.ps: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T ps $<  >$@

%.svg: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T svg $< >$@

%_graphvis.svg: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T svg $< >$@

# Weird latex errors embedding eps files made directly from dot
# seemingly resolved with recent graphviz (LaTeX?) packages, but I remember
# my work around here
#The following worked, but the latter three lines worked *better* when using eps imagefiles in dot
#${GRAPHVIS} ${GRAPHVISFLAGS} -T pdf -o /dev/stdout $< | pdf2ps - - | ps2eps -B - >$@
#${GRAPHVIS} ${GRAPHVISFLAGS} -Tps $< | ps2eps -B >$@
#epstopdf $@ #${@:.eps=.pdf}
#pdftops -f 1 -l 1 -eps ${@:.eps=.pdf} $@
#${RM} ${@:.eps=.pdf}
GVINKSCAPEPIPE=inkscape -p -T --export-ps-level 3 -o
%.eps: %.gv
ifneq (${GVINKSCAPEEPS},)
	${GRAPHVIS} ${GRAPHVISFLAGS} -T svg $< |${GVINKSCAPEPIPE} $@
else
ifneq (${GVPDF2PS2EPS},)
	${GRAPHVIS} ${GRAPHVISFLAGS} -T pdf -o /dev/stdout $< | pdf2ps - - | ps2eps -B - >$@
else
	${GRAPHVIS} ${GRAPHVISFLAGS} -T eps $<  >$@
endif
endif
%_graphvis.eps: %.gv
ifneq (${GVINKSCAPEEPS},)
	${GRAPHVIS} ${GRAPHVISFLAGS} -T svg $< |${GVINKSCAPEPIPE} $@
else
ifneq (${GVPDF2PS2EPS},)
	${GRAPHVIS} ${GRAPHVISFLAGS} -T pdf -o /dev/stdout $< | pdf2ps - - | ps2eps -B - >$@
else
	${GRAPHVIS} ${GRAPHVISFLAGS} -T eps $<  >$@
endif
endif


%.png: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T png $<  >$@

%.jpg: %.gv
	${GRAPHVIS} ${GRAPHVISFLAGS} -T jpeg $<  >$@

clean-graphvis:
	${RM} ${GRAPHVIS_ALL_TARGETS}

.PHONY: clean-graphvis
clean:: clean-graphvis


###############################################################################
# lilyPond rules (http://www.lilypond.org/
LILYPOND?=lilypond
#LILYPONDFLAGS?=
LILYPOND_SOURCE?= $(wildcard *.ly)
LILYPOND_PS_TARGETS?= $(patsubst %.ly,%.ps,${LILYPOND_SOURCE})
# warning:  lp doesn not embed fonts into PDFs which might lead to broken prints
LILYPOND_PDF_TARGETS?= $(patsubst %.ly,%.pdf,${LILYPOND_SOURCE})
LILYPOND_PNG_TARGETS?= $(patsubst %.ly,%.png,${LILYPOND_SOURCE})
LILYPOND_MIDI_TARGETS?= $(patsubst %.ly,%.midi,${LILYPOND_SOURCE})
LILYPOND_ALL_TARGETS?=${LILYPOND_PS_TARGETS} ${LILYPOND_PDF_TARGETS} ${LILYPOND_PNG_TARGETS} ${LILYPOND_MIDI_TARGETS}

ifneq (${LILYPOND_FLAGS},)
$(error LILYPOND_FLAGS should be LILYPONDFLAGS)
endif

%.ps: %.ly
	${LILYPOND} ${LILYPONDFLAGS} --ps $< 

%.pdf: %.ly
	${LILYPOND} ${LILYPONDFLAGS} --pdf $< 

%.png: %.ly
	${LILYPOND} ${LILYPONDFLAGS} --png $< 

clean-lilypond:
	${RM} ${LILYPOND_ALL_TARGETS}

.PHONY: clean-lilypond
clean:: clean-lilypond


###############################################################################
# reStructuredText rules
RST2HTML_TARGETS?= $(patsubst %.rst,%.html,$(filter-out show_%,${RSTSOURCE}))
# rst 'slides' should begin with the show_ prefix.
RST2S5_TARGETS?= $(patsubst show_%.rst,show_%.html,$(filter show_%,${RSTSOURCE}))
RST2LATEX_TARGETS?= $(patsubst %.rst,%.tex,$(filter-out show_%,${RSTSOURCE}))
RST2TXT_TARGETS?= $(patsubst %.rst,%.txt,$(filter-out show_%,${RSTSOURCE}))
RST2MAN_TARGETS?= $(patsubst %.rst,%.man,$(filter-out show_%,${RSTSOURCE}))

# You may want to provide dependencies such as:
#   all:: ${RST2HTML_TARGETS}
#   ${RST2HTML_TARGETS}: Project.mak
# in your Project.mak. Or specify:
#   RST2HTML_ALL_TARGETS=1
#   RST2S5_ALL_TARGETS=1
#   RST2LATEX_ALL_TARGETS=1
#   RST2TXT_ALL_TARGETS=1
#   RST2MAN_ALL_TARGETS=1

RST2HTML?=rst2html
RST2S5?=rst2s5
RST2HTMLFLAGS?=-stg
RST2LATEX?=rst2newlatex
RST2LATEXFLAGS?=
RST2ODF?=rst2odf
RST2ODFFLAGS?=
RST2XML?=rst2xml
RST2XMLFLAGS?=
RST2MAN?=rst2man
RST2MANFLAGS?=

# must have at least one defined, and we force it
clean-rst:: FORCE

show_%.html: show_%.rst
	${RST2S5} ${RST2S5FLAGS} $< $@
ifeq (${RST2S5_ALL_TARGETS},1)
all:: ${RST2S5_TARGETS}
clean-rst::
	${RM} ${RST2S5_TARGETS}
	${RM} -rf ui
endif

%.html: %.rst
	${RST2HTML} ${RST2HTMLFLAGS} $< $@
ifeq (${RST2HTML_ALL_TARGETS},1)
all:: ${RST2HTML_TARGETS}
clean-rst::
	${RM} ${RST2HTML_TARGETS}
endif

%.tex: %.rst
	${RST2LATEX} ${RST2LATEXFLAGS} $< $@
ifeq (${RST2LATEX_ALL_TARGETS},1)
all:: ${RST2LATEX_TARGETS}
clean-rst::
	${RM} ${RST2LATEX_TARGETS} 
endif

%.odf: %.rst
	${RST2ODF} ${RST2ODFFLAGS} $< $@
ifeq (${RST2ODT_ALL_TARGETS},1)
all:: ${RST2ODT_TARGETS}
clean-rst::
	${RM} ${RST2ODT_TARGETS} 
endif

%.xml: %.rst
	${RST2XML} ${RST2XMLFLAGS} $< $@
ifeq (${RST2XML_ALL_TARGETS},1)
all:: ${RST2XML_TARGETS}
clean-rst::
	${RM} ${RST2XML_TARGETS} 
endif

%.man: %.rst
	${RST2MAN} ${RST2MANFLAGS} $< >$@
ifeq (${RST2MAN_ALL_TARGETS},1)
all:: ${RST2MAN_TARGETS}
clean-rst::
	${RM} ${RST2MAN_TARGETS} 
endif

# col removes reverse and half reverse line feeds (man's way of bolding or underlining
# on terminals)
# the sed deletes the man specific first and last lines of output (section number, blah,
# blah, blah)
RST2TXT_ENCODING=US-ASCII
%.txt: %.rst
	${RST2MAN} ${RST2MANFLAGS} $< |man /dev/stdin | \
			col -b -x | \
			sed -e 1d -e '$$d' | \
			recode UTF-8.${RST2TXT_ENCODING} >$@
ifeq (${RST2TXT_ALL_TARGETS},1)
all:: ${RST2TXT_TARGETS}
clean-rst::
	${RM} ${RST2TXT_TARGETS} 
endif

clean:: clean-rst
###############################################################################


###############################################################################
# generic rules go last --- make prefers rules occuring first in Makefiles when constructing
# build chains
%_ps2pdf.pdf: %.ps
	${PS2PDF} ${PS2PDFFLAGS} $< $@

%.pdf: %.ps
	${PS2PDF} ${PS2PDFFLAGS} $< $@

%.pdf: %.eps
	${EPSTOPDF} ${EPSTOPDFFLAGS} --outfile $@ $<

%_pstopdf.pdf: %.eps
	${EPSTOPDF} ${EPSTOPDFFLAGS} --outfile $@ $<

%_pdftops.eps: %.pdf
	${PDFTOPS} -eps ${PDFTOPSFLAGS} $< $@

# some image conversions
%.${figps}: %.png
	${CONVERT} ${CONVERTFLAGS} $< $@

%.${figps}: %.jpg
	${CONVERT} ${CONVERTFLAGS} $< $@


###############################################################################
# primary build triggers
###############################################################################
# build objects, shared libs, static archives, then java classes
# I like to build the objects first because you really want to see all your
# compile errors as quickly as possible.  Whats the point of (re)building 
# shared libs when an object file for an application will fail and break
# your build.  Perhaps this is a 'premature optimization' for the size of 
# our projects, but it is a nice habit to get into when your source tree
# takes 20 minutes to build...
all:: ${OBJECTS}  ${TARGET_SO}  ${TARGET_A}  ${TARGET_APP}
all:: ${CLASSES}
all:: ${LATEXTARGET}

STRIP=strip
strip:: all
	${RM} *.o
	${STRIP} ${TARGET_SO} ${TARGET_A} ${TARGET_APP}


# clean standard backup files
clean::
	${RM} *.bak *~
	${RM} tags etags


.PHONY: clean-core
realclean:: clean-core
clean-core:
	${RM} core *.core

# create a tarball of all the arch source
ARCHTAR=tar
ARCHTAR_OPTIONS+=--exclude .cvs --exclude .svn
.PHONY: archtar archzip
archtar:
	tf=$$(basename $$(pwd)) ; \
	( cd ../ && ${ARCHTAR} cjfh ./$${tf}.tar.bz2 ${ARCHTAR_OPTIONS} $$(tla inventory --source $${tf} ${ARCHTAR_EXTRA_DIRS} )) ; \
	tar tvjf ../$${tf}.tar.bz2

ARCHZIP=zip
ARCHZIP_OPTIONS=-9r
archzip:
	tf=$$(basename $$(pwd)) ; \
	( cd ../ && ${ARCHZIP} ${ARCHZIP_OPTIONS} ./$${tf}.zip  $$(tla inventory --source $${tf} ${ARCHTAR_EXTRA_DIRS} )) ; \
	
realclean::
	tf=$$(basename $$(pwd)) ; rm -f ../$${tf}.tar.bz2 

## NOTES #######################################################################
# - this file comes from the 
#     http://www.students.mines.edu/~khellman/make-template.tar.gz
#   archive.
# - feel free to Email khellman@mines.edu if you have questions or suggestions
# 	concerning this Makefile.
# - more information on *all* things make(1) can be found in the make *info* pages,
#   online at http://www.gnu.org/software/make/
# - you can use the show-VARIABLE target to debug make variables, at the shell
#   type 
#     $make show-CLASSES
#   for instance, to show all the CLASSES you have defined
# - there is an easy way specify most FLAGS variables specifically for a
#   particular target.  See the example Project.mak file for details.  The exception
#   to this rule is CPPFLAGS, again see the Project.mak file for the correct
#   mechanism to use.
# - The 'clean' target only removes files built by your current make configuration,
# - The 'realclean' target is more pervasive, removing all the object, dependency,
#   shared libraries, static archives, and class files
# - If you have shared libraries that depend on other specific shared libraries,
#   (for instance libfoo.so must link against /some/dir/libbar.so, then specify this with
#     libfoo.so: SOLIBS:=-L/some/dir -lbar
#   in your Project.mak file.
#
## NOTES v2 ####################################################################
# - the second version cleans up some typos as well as provides latex support
# - for the most part you always want to go from latex to pdf, you can use pdflatex(2)
#   by specifying PDFLATEX=pdflatex in your Project.mak file
# - the default is to use the traditional tex->dvi->ps->pdf chain
# - there are two gotchas with latex documentation  (1) any reasonably complex
#   latex file is broken into multiple .tex files  (2) the best way to include
#   graphics is to generate LaTeX+[e]ps files - these can be produced from
#   gnuplot(2), dia(2), and xfig(2).  This is the optimal approach because this
#   format allows you to have sweet LaTeX math formatting in your figure, the
#   downside is that now you have an independent chain generating tex files which can 
#   be misinterpretted as *original* tex files, not outputs from a target chain.
#   One solution is to name your output tex files something awkward like *.pstex_t,
#   I don't like that because make the \input{} command more verbose and it doesn't
#   tranisition easily to using other graphic formats when required.
# - My solution is that the user is required to
#   (A) specify exactly the LATEXSOURCE files that are to be processed
#   (B) add these files to the LATEXCLEAN variable
#   The user already has to add a dependency, so this isn't really too much
#   additional work.
# - See the example in Project.mak
#
## NOTES v3 ####################################################################
# - the third version is long overdue, incorporating changes over at least a couple
#   of years.  Of note:
# - support for reStructuredText processing
# - better python linting support
# - all around general cleanup after a lot of experience using this template system
# - see Project.mak examples (look for the end for recent target examples)
#

