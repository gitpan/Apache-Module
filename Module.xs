/* ====================================================================
 * Copyright (c) 1995-1998 The Apache Group.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * 4. The names "Apache Server" and "Apache Group" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission.
 *
 * 5. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * THIS SOFTWARE IS PROVIDED BY THE APACHE GROUP ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE APACHE GROUP OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Group and was originally based
 * on public domain software written at the National Center for
 * Supercomputing Applications, University of Illinois, Urbana-Champaign.
 * For more information on the Apache Group and the Apache HTTP server
 * project, please see <http://www.apache.org/>.
 *
 */

/* $Id: Module.xs,v 1.2 1998/03/17 10:37:39 dougm Exp $ */
#include "modules/perl/mod_perl.h"

typedef module *Apache__Module;
typedef handler_rec *Apache__Handler;
typedef command_rec *Apache__Command;

typedef int (*handler_func) (request_rec *);
extern module *top_module;

XS(XS_Apache__Module_handler_dispatch)
{
    dXSARGS;
    request_rec *r;
    int result;
    handler_func handler = (handler_func) CvXSUBANY(cv).any_ptr;

    if (SvROK(ST(0)) && sv_derived_from(ST(0), "Apache")) {
	IV tmp = SvIV((SV*)SvRV(ST(0)));
	r = (Apache) tmp;
    }
    else 
	croak("r is not of type Apache!");
   
    result = (*handler)(r);

    ST(0) = sv_2mortal(newSViv(result));

    XSRETURN(1);
}

static CV *install_method(char *name, void *any)
{
    CV *cv = newXS(name, XS_Apache__Module_handler_dispatch, __FILE__);
    CvXSUBANY(cv).any_ptr = any;
    return cv;
}

static SV *handler2cv(handler_func fp)
{
    CV *meth;
    SV *RETVAL = Nullsv;

    if(fp) {
	meth = install_method(NULL, (void*)fp);
        RETVAL = newRV_noinc((SV*)meth);
    }
    
    return RETVAL;
}

#define handler2cvrv(fp) \
    if(!(RETVAL = handler2cv(fp))) XSRETURN_UNDEF

#define member_boolean(thing) \
    RETVAL = (thing) ? TRUE : FALSE

#define member_member(thing) \
    if(!(RETVAL = (thing))) XSRETURN_UNDEF

MODULE = Apache::Module		PACKAGE = Apache::Module	PREFIX=ap_mod_

INCLUDE: handlers.xsubs

Apache::Module
top_module(class)
    SV *class

    CODE:
    RETVAL = top_module;

    OUTPUT:
    RETVAL

Apache::Module
next(modp)
    Apache::Module modp

    CODE:
    RETVAL = modp->next;

    OUTPUT:
    RETVAL

const char *
name(modp)
    Apache::Module modp

    CODE:
    RETVAL = modp->name;

    OUTPUT:
    RETVAL

Apache::Handler
handlers(modp)
    Apache::Module modp

    CODE:
    if(modp->handlers)
        RETVAL = modp->handlers;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

Apache::Command
cmds(modp)
    Apache::Module modp

    CODE:
    if(modp->cmds)
        RETVAL = modp->cmds;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache::Handler

char *
content_type(hand)
    Apache::Handler hand

    CODE:
    if(hand && hand->content_type) 
        RETVAL = hand->content_type;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

Apache::Handler
next(hand)
    Apache::Handler hand

    CODE:
    hand++;
    if(hand && hand->content_type)
        RETVAL = hand;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache::Command

Apache::Command
find(cmd, name)
    Apache::Command cmd
    char *name

    CODE:
    while (cmd->name) {
	if (strEQ(name, cmd->name)) {
	    RETVAL = cmd;
	    break;
	}
	else 
	    ++cmd;
    }

    if(!(RETVAL = cmd)) 
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

Apache::Command
next(cmd)
    Apache::Command cmd

    CODE:
    cmd++;
    if(cmd && cmd->name)
        RETVAL = cmd;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

char *
name(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->name;

    OUTPUT:
    RETVAL

char *
errmsg(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->errmsg;

    OUTPUT:
    RETVAL

int
req_override(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->req_override;

    OUTPUT:
    RETVAL

SV *
args_how(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = newSV(0);

    sv_setnv(RETVAL, (double)cmd->args_how); 

    switch(cmd->args_how) {
    case RAW_ARGS:
	sv_setpv(RETVAL, "RAW_ARGS");
        break;
    case TAKE1:
	sv_setpv(RETVAL, "TAKE1");
        break;
    case TAKE2:
	sv_setpv(RETVAL, "TAKE2");
        break;
    case ITERATE:
	sv_setpv(RETVAL, "ITERATE");
        break;
    case ITERATE2:
	sv_setpv(RETVAL, "ITERATE2");
        break;
    case FLAG:
	sv_setpv(RETVAL, "FLAG");
        break;
    case NO_ARGS:
	sv_setpv(RETVAL, "NO_ARGS");
        break;
    case TAKE12:
	sv_setpv(RETVAL, "TAKE12");
        break;
    case TAKE3:
	sv_setpv(RETVAL, "TAKE3");
        break;
    case TAKE23:
	sv_setpv(RETVAL, "TAKE23");
        break;
    case TAKE123:
	sv_setpv(RETVAL, "TAKE123");
        break;
    case TAKE13:
	sv_setpv(RETVAL, "TAKE13");
        break;
    default:
	sv_setpv(RETVAL, "__UNKNOWN__");
        break;
    };

    SvNOK_on(RETVAL); /* ah, magic */ 

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache

int
location_walk(r)
    Apache r

int
file_walk(r)
    Apache r

int
directory_walk(r)
    Apache r


Apache
new_from_uri(r, new_file)
    Apache r
    char *new_file

    PREINIT:
    request_rec *rnew;
    int res;
    char *udir;

    CODE:
    rnew = (request_rec *)make_sub_request(r);
    rnew->request_time   = r->request_time;
    rnew->connection     = r->connection;
    rnew->server         = r->server;
    rnew->request_config = (void*)create_request_config(rnew->pool);
    rnew->htaccess       = r->htaccess;
    rnew->per_dir_config = r->server->lookup_defaults;
    rnew->connection->user = "";

    set_sub_req_protocol(rnew, r);

    if (new_file[0] == '/')
        parse_uri(rnew, new_file);
    else {
        udir = make_dirstr_parent(rnew->pool, r->uri);
        udir = escape_uri(rnew->pool, udir);    /* re-escape it */
        parse_uri(rnew, make_full_path(rnew->pool, udir, new_file));
    }

    res = unescape_url(rnew->uri);
    if(res) 
        rnew->status = res;
    else 
        getparents(rnew->uri);

    RETVAL = rnew;

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache::Server

int
timeout(server)
    Apache::Server	server

    CODE:
    RETVAL = server->timeout;

    OUTPUT:
    RETVAL

int
keep_alive_timeout(server)
    Apache::Server	server

    CODE:
    RETVAL = server->keep_alive_timeout;

    OUTPUT:
    RETVAL

int
keep_alive_max(server)
    Apache::Server	server

    CODE:
    RETVAL = server->keep_alive_timeout;

    OUTPUT:
    RETVAL

int
keep_alive(server)
    Apache::Server	server

    CODE:
    RETVAL = server->keep_alive;

    OUTPUT:
    RETVAL
