NAME=servletada

-include Makefile.conf

STATIC_MAKE_ARGS = $(MAKE_ARGS) -XSERVLET_LIBRARY_TYPE=static
SHARED_MAKE_ARGS = $(MAKE_ARGS) -XSERVLET_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XELADA_BUILD=relocatable -XEL_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XSECURITYADA_BUILD=relocatable -XSECURITY_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XUTILADA_BASE_BUILD=relocatable -XUTIL_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XXMLADA_BUILD=relocatable
SHARED_MAKE_ARGS += -XXMLADA_BUILD=relocatable -XAWS_BUILD=relocatable
SHARED_MAKE_ARGS += -XUTILADA_HTTP_AWS_BUILD=relocatable
SHARED_MAKE_ARGS += -XUTILADA_HTTP_AWS_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XUTILADA_UNIT_BUILD=relocatable
SHARED_MAKE_ARGS += -XUTIL_UNIT_LIBRARY_TYPE=relocatable
SHARED_MAKE_ARGS += -XLIBRARY_TYPE=relocatable
ifeq ($(HAVE_AWS),yes)
SHARED_MAKE_ARGS += -XAWS_BUILD=relocatable
endif

include Makefile.defaults

# Build executables for all mains defined by the project.
build-test:: setup
	$(GNATMAKE) $(GPRFLAGS) -p -Pservletada_tests $(MAKE_ARGS)

# Build and run the unit tests
test:	build runtest

runtest:
	DIR=`pwd`; \
	export LD_LIBRARY_PATH="$$DIR/lib/$(NAME)/relocatable:$$DIR/lib/$(NAME)/relocatable:$$LD_LIBRARY_PATH"; \
	export PATH="$$DIR/lib/$(NAME)/relocatable:$$DIR/lib/$(NAME)unit/relocatable:$$PATH"; \
	bin/servlet_harness -l $(NAME): -xml servlet-aunit.xml -config test.properties

$(eval $(call ada_library,$(NAME)))

ifeq ($(HAVE_AWS),yes)
$(eval $(call ada_library,servletada_aws))
endif

$(eval $(call ada_library,servletada_unit))

