#!/usr/bin/env python3
""" Fuzzware SSH-based experiment install helper

This script allows installing multiple Ubuntu cloud instances.

We performed our original tests on Ubuntu 18.04.6 LTS, however 20.04 has also previously worked for us.
"""
import argparse
import subprocess
from sys import exit
import os

DIR = os.path.dirname(os.path.realpath(__file__))

def print_ssh_config_suggestion(remote_host):
    print("== Possible configuration for ~/.ssh/config ==\n")
    print("Host fuzzware-*\n   User worker\n   IdentityFile ~/.ssh/<your_key>.key\n   AddKeysToAgent yes\n   IdentitiesOnly yes")
    print(f"\nHost {remote_host}\n   Hostname <remote_ip>")

    print(f"\nOr with /etc/hosts entry:\n<remote_ip> {remote_host}")

def ssh_check_cmd(remote_host, cmd="exit"):
    return subprocess.call(["ssh", "-t", "-q", remote_host, cmd]) == 0

def gen_hostname(host_num):
    return f"fuzzware-duo-{host_num:02d}"

DEFAULT_NUM_HOSTS=41
DEFAULT_HOST_START_INDEX=1
DEFAULT_GIT_REPO_SITE="github.com"
DEFAULT_GIT_REPO_OWNER="fuzzware-fuzzer"
# Latest commit, but made explicit for artifact eval purposes.
DEFAULT_FUZZWARE_COMMIT="424fce42bbe0cef3928ae589b8f6bbac666857e1"
def main():
    parser = argparse.ArgumentParser(description="Ubuntu Cloud Hosts Install Helper")
    parser.add_argument('--fuzzware-version', type=str, default=DEFAULT_FUZZWARE_COMMIT, help="(optional) Install a specific version of Fuzzware. Specify a tag name or fuzzware repo commit hash. The latest version of Fuzzware should cleanly replay crashing POC at the time of writing, but later versions may change the emulator behavior such that inputs replay slightly differently, which means crashing POC inputs may no longer reproduce.")
    parser.add_argument('--git-repo-site', type=str, default=DEFAULT_GIT_REPO_SITE, help=f"(optional) Site hosting git repos. Defaults to {DEFAULT_GIT_REPO_SITE}.")
    parser.add_argument('--git-repo-owner', type=str, default=DEFAULT_GIT_REPO_OWNER, help=f"(optional) Name of organization or user hosting fuzzware repos. Defaults to {DEFAULT_GIT_REPO_OWNER}.")
    parser.add_argument('--git-repo-ssh-key', type=str, default=None, help=f"(optional) SSH key for accessing git repo. Only required in case ssh-based authentication should be used by the newly installed hosts. By default, https-based repository cloning will be used.")
    parser.add_argument('-n', '--num-hosts', type=int, default=DEFAULT_NUM_HOSTS, help=f"(optional) The number of consecutively-named cloud hosts to install. Defaults to {DEFAULT_NUM_HOSTS}.")
    parser.add_argument('--host-start-index', type=int, default=DEFAULT_HOST_START_INDEX, help=f"(optional) The number within the host naming scheme to start with. Defaults to {DEFAULT_HOST_START_INDEX}.")
    parser.add_argument('--local', action="store_true", default=False, help="(optional) Instead of installing docker, install local instance of fuzzware. Defaults to false (docker-based install).")
    args = parser.parse_args()

    print("[*] Checking root access via SSH...")
    remote_hosts = []
    for host_num in range(args.host_start_index, args.host_start_index+args.num_hosts):
        remote_host = gen_hostname(host_num)
        if not ssh_check_cmd(f"root@{remote_host}"):
            print(f"{remote_host} ... fail")
            print(f"Could not access root user of host '{remote_host}'. Did you add an ssh config entry for this host?")
            print_ssh_config_suggestion(remote_host)
            exit(1)
        remote_hosts.append(remote_host)
        print(f"{remote_host} ... success")
    print("[+] All hosts root-accessible")

    procs = []
    print("[*] Setting up remote instances in parallel...")
    for remote_host in remote_hosts:
        print(f"Deploying {remote_host}")
        run_args = [os.path.join(DIR, "helper_scripts", "ssh_wrapper_install_fuzzware.sh"), remote_host]

        if args.git_repo_ssh_key is not None:
            run_args.append(args.git_repo_ssh_key)

        print("Popen args: ", " ".join(run_args))
        procs.append(subprocess.Popen(run_args, env={**os.environ, "GIT_REPO_SITE": args.git_repo_site, "GIT_REPO_OWNER": args.git_repo_owner, "USE_DOCKER_INSTALL": "0" if args.local else "1", "FUZZWARE_VERSION": args.fuzzware_version}))

    all_successful = True
    for hostname, proc in zip(remote_hosts, procs):
        status = proc.wait()
        if status == 0:
            print(f"[+] Installation of host {hostname} success!")
        else:
            print(f"[-] Installation of host {hostname} failed...")
            all_successful = False

    if not all_successful:
        print("[-] At least one installation failed")
        print("Possible causes are:")
        print("1. Ubuntu auto-upgrades are still running on a newly created cloud image. In this case, just wait for the auto updates to have finished up)")
        exit(1)

    print("[*] Checking fuzzware availability")
    for remote_host in remote_hosts:
        print(f"Testing fuzzware availability on {remote_host}...")
        if args.local:
            # Local install
            cmd = "source ~/.virtualenvs/fuzzware/bin/activate; fuzzware -h"
        else:
            # Docker command
            cmd = "~/fuzzware/run_docker.sh ~/fuzzware/examples fuzzware -h"
        if not ssh_check_cmd(remote_host, cmd):
            print(f"Could not run fuzzware in installed environment on host {remote_host} (tried running '{cmd}' on the host)")
            exit(1)
        print(f"{remote_host} ... success")

    print("\n[+++] All instances correctly configured! [+++]")

if __name__ == "__main__":
    main()