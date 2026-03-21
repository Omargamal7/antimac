/* Copyright (c) 2025 Eric Vidal <eric@obarun.org>
 *
 * All rights reserved.
 *
 * This file is part of Obarun. It is subject to the license terms in
 * the LICENSE file found in the top-level directory of this
 * distribution.
 * This file may not be copied, modified, propagated, or distributed
 * except according to the terms contained in the LICENSE file./
 */

#ifndef SS_CONFIG_H
#define SS_CONFIG_H

#define SS_VERSION "0.8.2.1"
#define SS_LIVE "/run/66/"
#define SS_MAX_SERVICE 500
#define SS_MAX_PATH 1024
#define SS_MAX_SERVICE_NAME 256
#define SS_MAX_TREENAME 256
#define SS_DEFAULT_TREENAME "global"
#define SS_SYSTEM_DIR "/var/lib/66/"
#define SS_SKEL_DIR "/etc/66/"
#define SS_LOGGER_SYSDIR "/var/log/66/"
#define SS_LOGGER_RUNNER "root"
#define SS_LOGGER_TIMESTAMP 1
#define SS_LOGGER_NOTIFY 1
#define SS_SERVICE_SYSDIR "/usr/share/66/service/"
#define SS_SERVICE_SYSDIR_USER "/usr/share/66/service/user/"
#define SS_SERVICE_ADMDIR "/etc/66/service/"
#define SS_SERVICE_ADMDIR_USER "/etc/66/service/user/"
#define SS_SERVICE_ADMCONFDIR "/etc/66/conf/"
#define SS_SCRIPT_SYSDIR "/usr/share/66/script/"
#define SS_SEED_SYSDIR "/usr/share/66/seed/"
#define SS_SEED_ADMDIR "/etc/66/seed/"
#define SS_ENVIRONMENT_ADMDIR "/etc/66/environment/"
#define SS_USER_DIR ".66/"
#define SS_LOGGER_USERDIR ".66/log/"
#define SS_SERVICE_USERDIR ".66/service/"
#define SS_SERVICE_USERCONFDIR ".66/conf/"
#define SS_SCRIPT_USERDIR ".66/script/"
#define SS_SEED_USERDIR ".66/seed/"
#define SS_ENVIRONMENT_USERDIR ".66/environment/"
#define SS_BINPREFIX "/usr/bin/"
#define SS_EXTBINPREFIX ""
#define SS_EXTLIBEXECPREFIX "/usr/libexec/"
#define SS_LIBEXECPREFIX "/usr/libexec/"
#define SS_EXECLINE_SHEBANGPREFIX "/usr/bin/"

#endif