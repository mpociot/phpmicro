PHP_ARG_ENABLE([micro],,
  [AS_HELP_STRING([--enable-micro],
    [enable building micro PHP sfx ])],
  [no],
  [no])

dnl AC_CHECK_FUNCS(setproctitle)

dnl AC_CHECK_HEADERS([sys/pstat.h])

dnl AC_CACHE_CHECK([for PS_STRINGS], [cli_cv_var_PS_STRINGS],
dnl [AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <machine/vmparam.h>
dnl #include <sys/exec.h>
dnl ]],
dnl [[PS_STRINGS->ps_nargvstr = 1;
dnl PS_STRINGS->ps_argvstr = "foo";]])],
dnl [cli_cv_var_PS_STRINGS=yes],
dnl [cli_cv_var_PS_STRINGS=no])])
dnl if test "$cli_cv_var_PS_STRINGS" = yes ; then
dnl   AC_DEFINE([HAVE_PS_STRINGS], [], [Define to 1 if the PS_STRINGS thing exists.])
dnl fi

AC_MSG_CHECKING(for micro build)
if test "$PHP_MICRO" != "no"; then
  AC_MSG_RESULT(yes)

  AC_CHECK_TOOL(STRIP, strip, :)
  PHP_SUBST(STRIP)
dnl prepare stat command
  AC_CHECK_TOOL(STAT_CMD, stat)
  if test "x$STAT_CMD" = "x"; then
    AC_MSG_FAILURE(micro SAPI needs stat command to finish 2-step build.)
  fi
  AC_CHECK_TOOL(MKTEMP, mktemp)
  if test "x$MKTEMP" != "x"; then
    micro_tempfile=`$MKTEMP`
  else
    micro_tempfile=`conftest.tmp`
  fi
  echo cafebabe > ${micro_tempfile}
  AC_MSG_CHECKING(if we using gnu stat)
  if test x`$STAT_CMD -c '%s' ${micro_tempfile} 2>&AS_MESSAGE_LOG_FD` = "x9"; then
    AC_MSG_RESULT(yes)
    STAT_SIZE="${STAT_CMD} -c '%s'"
  else
    AC_MSG_RESULT(no)
  fi
  if test "x$STAT_SIZE" = "x"; then
    AC_MSG_CHECKING(if we using bsd stat)
    if test x`$STAT_CMD -f '%z' ${micro_tempfile} 2>&AS_MESSAGE_LOG_FD` = "x9"; then
      AC_MSG_RESULT(yes)
      STAT_SIZE="${STAT_CMD} -f '%z'"
    else
      AC_MSG_RESULT(no)
    fi
  fi
  if test "x$STAT_SIZE" = "x"; then
    AC_MSG_FAILURE(micro SAPI donot support that stat command)
  fi
  rm ${micro_tempfile}
  PHP_SUBST(STAT_SIZE)

  PHP_ADD_MAKEFILE_FRAGMENT($abs_srcdir/sapi/micro/Makefile.frag)

  dnl Set filename.
  SAPI_MICRO_PATH=sapi/micro/micro.sfx

  dnl Select SAPI.
  CFLAGS="$CFLAGS -DPHP_MICRO_BUILD_SFX"
  PHP_SELECT_SAPI(micro, program, php_micro.c php_micro_helper.c, -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1, '$(SAPI_MICRO_PATH)')
  PHP_SUBST(MICRO_2STAGE_OBJS)
  PHP_ADD_SOURCES_X(sapi/micro, php_micro_fileinfo.c, -DSFX_FILESIZE=\$(SFX_FILESIZE), MICRO_2STAGE_OBJS)

  case $host_alias in
  *aix*)
    AC_MSG_ERROR(not yet support aix)
    
    if test "$php_sapi_module" = "shared"; then
      BUILD_MICRO="echo '\#! .' > php.sym && echo >>php.sym && nm -BCpg \`echo \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_MICRO_OBJS) | sed 's/\([A-Za-z0-9_]*\)\.lo/.libs\/\1.o/g'\` | \$(AWK) '{ if (((\$\$2 == \"T\") || (\$\$2 == \"D\") || (\$\$2 == \"B\")) && (substr(\$\$3,1,1) != \".\")) { print \$\$3 } }' | sort -u >> php.sym && \$(LIBTOOL) --mode=link \$(CC) -export-dynamic \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) -Wl,-brtl -Wl,-bE:php.sym \$(PHP_RPATHS) \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_MICRO_OBJS) \$(EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_MICRO_PATH)"
    else
      BUILD_MICRO="echo '\#! .' > php.sym && echo >>php.sym && nm -BCpg \`echo \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_MICRO_OBJS) | sed 's/\([A-Za-z0-9_]*\)\.lo/\1.o/g'\` | \$(AWK) '{ if (((\$\$2 == \"T\") || (\$\$2 == \"D\") || (\$\$2 == \"B\")) && (substr(\$\$3,1,1) != \".\")) { print \$\$3 } }' | sort -u >> php.sym && \$(LIBTOOL) --mode=link \$(CC) -export-dynamic \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) -Wl,-brtl -Wl,-bE:php.sym \$(PHP_RPATHS) \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_MICRO_OBJS) \$(EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_MICRO_PATH)"
    fi
    ;;
  *darwin*)
    BUILD_MICRO="\$(CC) \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) \$(NATIVE_RPATHS) \$(PHP_GLOBAL_OBJS:.lo=.o) \$(PHP_BINARY_OBJS:.lo=.o) \$(PHP_MICRO_OBJS:.lo=.o) \$(MICRO_2STAGE_OBJS:.lo=.o) \$(PHP_FRAMEWORKS) \$(EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_MICRO_PATH)"
    MICRO_STRIP_FLAGS=""
    ;;
  *)
    EXTRA_LDFLAGS_PROGRAM="$EXTRA_LDFLAGS_PROGRAM -all-static"
    PHP_SUBST(EXTRA_LDFLAGS)
    BUILD_MICRO="\$(LIBTOOL) --mode=link \$(CC) -export-dynamic \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) \$(PHP_RPATHS) \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_MICRO_OBJS) \$(MICRO_2STAGE_OBJS) \$(EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_MICRO_PATH)"
    MICRO_STRIP_FLAGS="-s"
    ;;
  esac

  dnl Set executable for tests.
  dnl PHP_EXECUTABLE="\$(top_builddir)/\$(SAPI_CLI_PATH)"
  dnl PHP_SUBST(PHP_EXECUTABLE)

  dnl Expose to Makefile.
  PHP_SUBST(MICRO_STRIP_FLAGS)
  PHP_SUBST(SAPI_MICRO_PATH)
  PHP_SUBST(BUILD_MICRO)

  dnl PHP_OUTPUT(sapi/cli/php.1)

  dnl PHP_INSTALL_HEADERS([sapi/cli/cli.h])
fi