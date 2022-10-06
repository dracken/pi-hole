#!/usr/bin/env bash
# Pi-hole: A black hole for Internet advertisements
# (c) 2017 Pi-hole, LLC (https://pi-hole.net)
# Network-wide ad blocking via your own hardware.
#
# Checks for local or remote versions and branches
#
# This file is copyright under the latest version of the EUPL.
# Please see LICENSE file for your rights under this license.

function get_local_branch() {
    # Return active branch
    cd "${1}" 2> /dev/null || return 1
    git rev-parse --abbrev-ref HEAD || return 1
}

function get_local_version() {
    # Return active branch
    cd "${1}" 2> /dev/null || return 1
    git describe --long --dirty --tags 2> /dev/null || return 1
}

function get_remote_version() {
    curl -s "https://api.github.com/repos/pi-hole/${1}/releases/latest" 2> /dev/null | jq --raw-output .tag_name || return 1
}

# Source the setupvars config file
# shellcheck disable=SC1091
. /etc/pihole/setupVars.conf

# Source the utils file for addOrEditKeyValPair()
# shellcheck disable=SC1091
. /opt/pihole/utils.sh

# Remove the below three legacy files if they exist
rm -f "/etc/pihole/GitHubVersions"
rm -f "/etc/pihole/localbranches"
rm -f "/etc/pihole/localversions"

# Create new versions file if it does not exist
VERSION_FILE="/etc/pihole/versions"
touch "${VERSION_FILE}"
chmod 644 "${VERSION_FILE}"

# if /pihole.docker.tag file exists, we will use it's value later in this script
DOCKER_TAG=$(cat /pihole.docker.tag 2>/dev/null)
regex='^([0-9]+\.){1,2}(\*|[0-9]+)(-.*)?$|(^nightly$)|(^dev.*$)'
if [[ ! "${DOCKER_TAG}" =~ $regex ]]; then
  # DOCKER_TAG does not match the pattern (see https://regex101.com/r/RsENuz/1), so unset it.
  unset DOCKER_TAG
fi

# used in cronjob
if [[ "$1" == "reboot" ]]; then
        sleep 30
fi


# get local versions

CORE_BRANCH="$(get_local_branch /etc/.pihole)"
addOrEditKeyValPair "${VERSION_FILE}" "CORE_BRANCH" "${CORE_BRANCH}"

if [[ "${INSTALL_WEB_INTERFACE}" == true ]]; then
    WEB_BRANCH="$(get_local_branch /var/www/html/admin)"
    addOrEditKeyValPair "${VERSION_FILE}" "WEB_BRANCH" "${WEB_BRANCH}"
fi

FTL_BRANCH="$(pihole-FTL branch)"
addOrEditKeyValPair "${VERSION_FILE}" "FTL_BRANCH" "${FTL_BRANCH}"

CORE_VERSION="$(get_local_version /etc/.pihole)"
addOrEditKeyValPair "${VERSION_FILE}" "CORE_VERSION" "${CORE_VERSION}"

if [[ "${INSTALL_WEB_INTERFACE}" == true ]]; then
    WEB_VERSION="$(get_local_version /var/www/html/admin)"
    addOrEditKeyValPair "${VERSION_FILE}" "WEB_VERSION" "${WEB_VERSION}"
fi

FTL_VERSION="$(pihole-FTL version)"
addOrEditKeyValPair "${VERSION_FILE}" "FTL_VERSION" "${FTL_VERSION}"

if [[ "${DOCKER_TAG}" ]]; then
    addOrEditKeyValPair "${VERSION_FILE}" "DOCKER_VERSION" "${DOCKER_TAG}"
fi


# get remote versions

GITHUB_CORE_VERSION="$(get_remote_version pi-hole)"
addOrEditKeyValPair "${VERSION_FILE}" "GITHUB_CORE_VERSION" "${GITHUB_CORE_VERSION}"

if [[ "${INSTALL_WEB_INTERFACE}" == true ]]; then
    GITHUB_WEB_VERSION="$(get_remote_version AdminLTE)"
    addOrEditKeyValPair "${VERSION_FILE}" "GITHUB_WEB_VERSION" "${GITHUB_WEB_VERSION}"
fi

GITHUB_FTL_VERSION="$(get_remote_version FTL)"
addOrEditKeyValPair "${VERSION_FILE}" "GITHUB_FTL_VERSION" "${GITHUB_FTL_VERSION}"

if [[ "${DOCKER_TAG}" ]]; then
    GITHUB_DOCKER_VERSION="$(get_remote_version docker-pi-hole)"
    addOrEditKeyValPair "${VERSION_FILE}" "GITHUB_DOCKER_VERSION" "${GITHUB_DOCKER_VERSION}"
fi
