#!/bin/bash

source experiment/run-library.sh

organization="${PARAM_organization:-Default Organization}"
manifest="${PARAM_manifest:-conf/contperf/manifest_SCA.zip}"
inventory="${PARAM_inventory:-conf/contperf/inventory.ini}"
local_conf="${PARAM_local_conf:-conf/satperf.local.yaml}"

wait_interval="${PARAM_wait_interval:-30}"

puppet_one_concurency="${PARAM_puppet_one_concurency:-5 15 30}"
puppet_bunch_concurency="${PARAM_puppet_bunch_concurency:-2 6 10 14 18}"

cdn_url_mirror="${PARAM_cdn_url_mirror:-https://cdn.redhat.com/}"
cdn_url_full="${PARAM_cdn_url_full:-https://cdn.redhat.com/}"

repo_sat_tools="${PARAM_repo_sat_tools:-http://mirror.example.com/Satellite_Tools_x86_64/}"
repo_sat_tools_puppet="${PARAM_repo_sat_tools_puppet:-none}"   # Older example: http://mirror.example.com/Satellite_Tools_Puppet_4_6_3_RHEL7_x86_64/

repo_sat_client_7="${PARAM_repo_sat_client_7:-http://mirror.example.com/Satellite_Client_7_x86_64/}"
repo_sat_client_8="${PARAM_repo_sat_client_8:-http://mirror.example.com/Satellite_Client_8_x86_64/}"
repo_sat_client_9="${PARAM_repo_sat_client_9:-http://mirror.example.com/Satellite_Client_9_x86_64/}"

rhel_subscription="${PARAM_rhel_subscription:-Red Hat Enterprise Linux Server, Standard (Physical or Virtual Nodes)}"

initial_expected_concurrent_registrations="${PARAM_initial_expected_concurrent_registrations:-25}"

test_sync_repositories_count="${PARAM_test_sync_repositories_count:-8}"
test_sync_repositories_url_template="${PARAM_test_sync_repositories_url_template:-http://repos.example.com/repo*}"
test_sync_repositories_max_sync_secs="${PARAM_test_sync_repositories_max_sync_secs:-600}"
test_sync_iso_count="${PARAM_test_sync_iso_count:-8}"
test_sync_iso_url_template="${PARAM_test_sync_iso_url_template:-http://storage.example.com/iso-repos*}"
test_sync_iso_max_sync_secs="${PARAM_test_sync_iso_max_sync_secs:-600}"
test_sync_docker_count="${PARAM_test_sync_docker_count:-8}"
test_sync_docker_url_template="${PARAM_test_sync_docker_url_template:-https://registry-1.docker.io}"
test_sync_docker_max_sync_secs="${PARAM_test_sync_docker_max_sync_secs:-600}"

ui_pages_concurrency="${PARAM_ui_pages_concurrency:-10}"
ui_pages_duration="${PARAM_ui_pages_duration:-300}"

dl="Default Location"

opts="--forks 100 -i $inventory"
opts_adhoc="$opts -e @conf/satperf.yaml -e @$local_conf"


section "Checking environment"
generic_environment_check


section "Prepare for Red Hat content"
h_out "--no-headers --csv organization list --fields name" | grep --quiet "^$organization$" \
  || h 00-ensure-org.log "organization create --name '$organization'"
skip_measurement='true' h 00-ensure-loc-in-org.log "organization add-location --name '$organization' --location '$dl'"
skip_measurement='true' ap 01-manifest-excercise.log \
  -e "manifest=../../$manifest" \
  playbooks/tests/manifest-excercise.yaml
e ManifestUpload $logs/01-manifest-excercise.log
e ManifestRefresh $logs/01-manifest-excercise.log
e ManifestDelete $logs/01-manifest-excercise.log
skip_measurement='true' h 02-manifest-upload.log "subscription upload --file '/root/manifest-auto.zip' --organization '$organization'"
s $wait_interval


section "Sync from mirror"
skip_measurement='true' h 00-set-local-cdn-mirror.log "organization update --name '$organization' --redhat-repository-url '$cdn_url_mirror'"

skip_measurement='true' h 00-manifest-refresh.log "subscription refresh-manifest --organization '$organization'"

# RHEL 6
skip_measurement='true' h 10-reposet-enable-rhel6.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 6 Server (RPMs)' --releasever '6Server' --basearch 'x86_64'"
h 12-repo-sync-rhel6.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server'"
s $wait_interval

# RHEL 7
skip_measurement='true' h 10-reposet-enable-rhel7.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)' --releasever '7Server' --basearch 'x86_64'"
skip_measurement='true' h 11-repo-immediate-rhel7.log "repository update --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server' --download-policy 'immediate'"
h 12-repo-sync-rhel7.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'"
s $wait_interval
skip_measurement='true' h 10-reposet-enable-rhel7optional.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)' --releasever '7Server' --basearch 'x86_64'"
h 12-repo-sync-rhel7optional.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server - Optional RPMs x86_64 7Server'"
s $wait_interval

# RHEL 8
skip_measurement='true' h 10-reposet-enable-rhel8baseos.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)' --releasever '8' --basearch 'x86_64'"
h 12-repo-sync-rhel8baseos.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8'"
s $wait_interval
skip_measurement='true' h 10-reposet-enable-rhel8appstream.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)' --releasever '8' --basearch 'x86_64'"
h 12-repo-sync-rhel8appstream.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8'"
s $wait_interval

# RHEL 9
skip_measurement='true' h 10-reposet-enable-rhel9baseos.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)' --releasever '9' --basearch 'x86_64'"
h 12-repo-sync-rhel9baseos.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - BaseOS RPMs 9'"
s $wait_interval
skip_measurement='true' h 10-reposet-enable-rhel9appstream.log "repository-set enable --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)' --releasever '9' --basearch 'x86_64'"
h 12-repo-sync-rhel9appstream.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - AppStream RPMs 9'"
s $wait_interval


section "Synchronise capsules"
ap 14-capsync-populate.log \
  -e "organization='$organization'" \
  playbooks/satellite/capsules-populate.yaml
s $wait_interval


section "Publish and promote big CV"
rids="$( get_repo_id 'Red Hat Enterprise Linux Server' 'Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server' )"
rids="$rids,$( get_repo_id 'Red Hat Enterprise Linux Server' 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server' )"
rids="$rids,$( get_repo_id 'Red Hat Enterprise Linux Server' 'Red Hat Enterprise Linux 7 Server - Optional RPMs x86_64 7Server' )"

skip_measurement='true' h 20-cv-create-all.log "content-view create --organization '$organization' --repository-ids '$rids' --name 'BenchContentView'"
h 21-cv-all-publish.log "content-view publish --organization '$organization' --name 'BenchContentView'"
s $wait_interval

skip_measurement='true' h 22-le-create-1.log "lifecycle-environment create --organization '$organization' --prior 'Library' --name 'BenchLifeEnvAAA'"
skip_measurement='true' h 22-le-create-2.log "lifecycle-environment create --organization '$organization' --prior 'BenchLifeEnvAAA' --name 'BenchLifeEnvBBB'"
skip_measurement='true' h 22-le-create-3.log "lifecycle-environment create --organization '$organization' --prior 'BenchLifeEnvBBB' --name 'BenchLifeEnvCCC'"

h 23-cv-all-promote-1.log "content-view version promote --organization '$organization' --content-view 'BenchContentView' --to-lifecycle-environment 'Library' --to-lifecycle-environment 'BenchLifeEnvAAA'"
s $wait_interval
h 23-cv-all-promote-2.log "content-view version promote --organization '$organization' --content-view 'BenchContentView' --to-lifecycle-environment 'BenchLifeEnvAAA' --to-lifecycle-environment 'BenchLifeEnvBBB'"
s $wait_interval
h 23-cv-all-promote-3.log "content-view version promote --organization '$organization' --content-view 'BenchContentView' --to-lifecycle-environment 'BenchLifeEnvBBB' --to-lifecycle-environment 'BenchLifeEnvCCC'"
s $wait_interval


section "Publish and promote filtered CV"
export skip_measurement='true'
rids="$( get_repo_id 'Red Hat Enterprise Linux Server' 'Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server' )"

h 30-cv-create-filtered.log "content-view create --organization '$organization' --repository-ids '$rids' --name 'BenchFilteredContentView'"

h 31-filter-create-1.log "content-view filter create --organization '$organization' --type erratum --inclusion true --content-view BenchFilteredContentView --name BenchFilterAAA"
h 31-filter-create-2.log "content-view filter create --organization '$organization' --type erratum --inclusion true --content-view BenchFilteredContentView --name BenchFilterBBB"

h 32-rule-create-1.log "content-view filter rule create --content-view BenchFilteredContentView --content-view-filter BenchFilterAAA --date-type 'issued' --start-date 2016-01-01 --end-date 2017-10-01 --organization '$organization' --types enhancement,bugfix,security"
h 32-rule-create-2.log "content-view filter rule create --content-view BenchFilteredContentView --content-view-filter BenchFilterBBB --date-type 'updated' --start-date 2016-01-01 --end-date 2018-01-01 --organization '$organization' --types security"
unset skip_measurement

h 33-cv-filtered-publish.log "content-view publish --organization '$organization' --name 'BenchFilteredContentView'"
s $wait_interval


export skip_measurement='true'
section "Sync from CDN do not measure"   # do not measure becasue of unpredictable network latency
h 00b-set-cdn-stage.log "organization update --name '$organization' --redhat-repository-url '$cdn_url_full'"

h 00b-manifest-refresh.log "subscription refresh-manifest --organization '$organization'"

# RHEL 6
h 12b-repo-sync-rhel6.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server'" &

# RHEL 7
h 12b-repo-sync-rhel7.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'" &
h 12b-repo-sync-rhel7optional.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux Server' --name 'Red Hat Enterprise Linux 7 Server - Optional RPMs x86_64 7Server'" &

# RHEL 8
h 12b-repo-sync-rhel8baseos.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs 8'" &
h 12b-repo-sync-rhel8appstream.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 8 for x86_64 - AppStream RPMs 8'" &

# RHEL 9
h 12b-repo-sync-rhel9baseos.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - BaseOS RPMs 9'" &
h 12b-repo-sync-rhel9appstream.log "repository synchronize --organization '$organization' --product 'Red Hat Enterprise Linux for x86_64' --name 'Red Hat Enterprise Linux 9 for x86_64 - AppStream RPMs 9'" &
wait
unset skip_measurement


export skip_measurement='true'
section "Sync Tools repo"
h product-create.log "product create --organization '$organization' --name SatToolsProduct"

h repository-create-sat-tools.log "repository create --organization '$organization' --product SatToolsProduct --name SatToolsRepo --content-type yum --url '$repo_sat_tools'"
[ "$repo_sat_tools_puppet" != "none" ] \
  && h repository-create-puppet-upgrade.log "repository create --organization '$organization' --product SatToolsProduct --name SatToolsPuppetRepo --content-type yum --url '$repo_sat_tools_puppet'"

h repository-sync-sat-tools.log "repository synchronize --organization '$organization' --product SatToolsProduct --name SatToolsRepo" &
[ "$repo_sat_tools_puppet" != "none" ] \
  && h repository-sync-puppet-upgrade.log "repository synchronize --organization '$organization' --product SatToolsProduct --name SatToolsPuppetRepo" &
wait
unset skip_measurement


export skip_measurement='true'
section "Sync Satellite Client repos"
h 30-sat-client-product-create.log "product create --organization '$organization' --name SatClientProduct"

# Satellite Client for RHEL 7
h 30-repository-create-sat-client_7.log "repository create --organization '$organization' --product SatClientProduct --name SatClient7Repo --content-type yum --url '$repo_sat_client_7'"
h 30-repository-sync-sat-client_7.log "repository synchronize --organization '$organization' --product SatClientProduct --name SatClient7Repo" &

# Satellite Client for RHEL 8
h 30-repository-create-sat-client_8.log "repository create --organization '$organization' --product SatClientProduct --name SatClient8Repo --content-type yum --url '$repo_sat_client_8'"
h 30-repository-sync-sat-client_8.log "repository synchronize --organization '$organization' --product SatClientProduct --name SatClient8Repo" &

# Satellite Client for RHEL 9
h 30-repository-create-sat-client_9.log "repository create --organization '$organization' --product SatClientProduct --name SatClient9Repo --content-type yum --url '$repo_sat_client_9'"
h 30-repository-sync-sat-client_9.log "repository synchronize --organization '$organization' --product SatClientProduct --name SatClient9Repo" &
wait
unset skip_measurement


export skip_measurement='true'
section "Synchronise capsules again"   # We just added up2date content from CDN, SatToolsRepo and SatClient7Repo, so no reason to measure this now
ap 14b-capsync-populate.log \
  -e "organization='$organization'" \
  playbooks/satellite/capsules-populate.yaml
s $wait_interval
unset skip_measurement


export skip_measurement='true'
section "Prepare for registrations"
h_out "--no-headers --csv domain list --search 'name = {{ domain }}'" | grep --quiet '^[0-9]\+,' \
  || h 42-domain-create.log "domain create --name '{{ domain }}' --organizations '$organization'"
tmp=$( mktemp )
h_out "--no-headers --csv location list --organization '$organization'" | grep '^[0-9]\+,' >$tmp
location_ids=$( cut -d ',' -f 1 $tmp | tr '\n' ',' | sed 's/,$//' )
h 42-domain-update.log "domain update --name '{{ domain }}' --organizations '$organization' --location-ids '$location_ids'"

h 43-ak-create.log "activation-key create --content-view '$organization View' --lifecycle-environment Library --name ActivationKey --organization '$organization'"
h_out "--csv subscription list --organization '$organization' --search 'name = SatToolsProduct'" >$logs/subs-list-tools.log
tools_subs_id=$( tail -n 1 $logs/subs-list-tools.log | cut -d ',' -f 1 )
h 43-ak-add-subs-tools.log "activation-key add-subscription --organization '$organization' --name ActivationKey --subscription-id '$tools_subs_id'"
h_out "--csv subscription list --organization '$organization' --search 'name = \"$rhel_subscription\"'" >$logs/subs-list-rhel.log
rhel_subs_id=$( tail -n 1 $logs/subs-list-rhel.log | cut -d ',' -f 1 )
h 43-ak-add-subs-rhel.log "activation-key add-subscription --organization '$organization' --name ActivationKey --subscription-id '$rhel_subs_id'"
h_out "--csv subscription list --organization '$organization' --search 'name = SatClientProduct'" >$logs/subs-list-client.log
client_subs_id=$( tail -n 1 $logs/subs-list-client.log | cut -d ',' -f 1 )
h 43-ak-add-subs-client.log "activation-key add-subscription --organization '$organization' --name ActivationKey --subscription-id '$client_subs_id'"

tmp=$( mktemp )
h_out "--no-headers --csv capsule list --organization '$organization'" | grep '^[0-9]\+,' >$tmp
for row in $( cut -d ' ' -f 1 $tmp ); do
    capsule_id=$( echo "$row" | cut -d ',' -f 1 )
    capsule_name=$( echo "$row" | cut -d ',' -f 2 )
    subnet_name="subnet-for-$capsule_name"
    hostgroup_name="hostgroup-for-$capsule_name"
    if [ "$capsule_id" -eq 1 ]; then
        location_name="$dl"
    else
        location_name="Location for $capsule_name"
    fi

    h_out "--no-headers --csv subnet list --search 'name = $subnet_name'" | grep --quiet '^[0-9]\+,' \
      || h 44-subnet-create-$capsule_name.log "subnet create --name '$subnet_name' --ipam None --domains '{{ domain }}' --organization '$organization' --network 172.0.0.0 --mask 255.0.0.0 --location '$location_name'"
    subnet_id=$( h_out "--output yaml subnet info --name '$subnet_name'" | grep '^Id:' | cut -d ' ' -f 2 )

    a 45-subnet-add-rex-capsule-$capsule_name.log satellite6 \
      -m "shell" \
      -a "curl --silent --insecure -u {{ sat_user }}:{{ sat_pass }} -X PUT -H 'Accept: application/json' -H 'Content-Type: application/json' https://localhost//api/v2/subnets/$subnet_id -d '{\"subnet\": {\"remote_execution_proxy_ids\": [\"$capsule_id\"]}}'"
    h_out "--no-headers --csv hostgroup list --search 'name = $hostgroup_name'" | grep --quiet '^[0-9]\+,' \
      || ap 41-hostgroup-create-$capsule_name.log \
           -e "organization='$organization'" \
           -e "hostgroup_name=$hostgroup_name" \
           -e "subnet_name=$subnet_name" \
           playbooks/satellite/hostgroup-create.yaml
done

ap 44-generate-host-registration-command.log \
  -e "ak=ActivationKey" \
  playbooks/satellite/host-registration_generate-command.yaml
ap 44-recreate-client-scripts.log \
  -e "registration_hostgroup=hostgroup-for-{{ tests_registration_target }}" \
  playbooks/satellite/client-scripts.yaml
unset skip_measurement


section "Incremental registrations"
number_container_hosts=$( ansible -i $inventory --list-hosts container_hosts 2>/dev/null | grep '^  hosts' | sed 's/^  hosts (\([0-9]\+\)):$/\1/' )
number_containers_per_container_host=$( ansible -i $inventory -m debug -a "var=containers_count" container_hosts[0] | awk '/    "containers_count":/ {print $NF}' )
if (( initial_expected_concurrent_registrations > number_container_hosts )); then
    initial_concurrent_registrations_per_container_host="$(( initial_expected_concurrent_registrations / number_container_hosts ))"
else
    initial_concurrent_registrations_per_container_host=1
fi

for (( batch=1, remaining_containers_per_container_host=$number_containers_per_container_host; remaining_containers_per_container_host > 0; batch++ )); do
    if (( remaining_containers_per_container_host > initial_concurrent_registrations_per_container_host * batch )); then
        concurrent_registrations_per_container_host="$(( initial_concurrent_registrations_per_container_host * batch ))"
    else
        concurrent_registrations_per_container_host="$(( remaining_containers_per_container_host ))"
    fi
    concurrent_registrations="$(( concurrent_registrations_per_container_host * number_container_hosts ))"
    (( remaining_containers_per_container_host -= concurrent_registrations_per_container_host ))

    log "Trying to register $concurrent_registrations content hosts concurrently in this batch"

    skip_measurement='true' ap 44-register-$concurrent_registrations.log \
      -e "size=$concurrent_registrations_per_container_host" \
      -e "registration_logs='../../$logs/44-register-docker-host-client-logs'" \
      -e 're_register_failed_hosts=true' \
      playbooks/tests/registrations.yaml
      e Register $logs/44-register-$concurrent_registrations.log
    s $wait_interval
done
grep Register $logs/44-register-*.log >$logs/44-register-overall.log
e Register $logs/44-register-overall.log


section "Remote execution"
job_template_ansible_default='Run Command - Ansible Default'
if vercmp_ge "$satellite_version" "6.12.0"; then
    job_template_ssh_default='Run Command - Script Default'
else
    job_template_ssh_default='Run Command - SSH Default'
fi

skip_measurement='true' h 50-rex-set-via-ip.log "settings set --name remote_execution_connect_by_ip --value true"
skip_measurement='true' a 51-rex-cleanup-know_hosts.log \
  -m "shell" \
  -a "rm -rf /usr/share/foreman-proxy/.ssh/known_hosts*" \
  satellite6

skip_measurement='true' h 55-rex-date.log "job-invocation create --async --description-format 'Run %{command} (%{template_name})' --inputs command='date' --job-template '$job_template_ssh_default' --search-query 'name ~ container'"
j $logs/55-rex-date.log
s $wait_interval

skip_measurement='true' h 56-rex-date-ansible.log "job-invocation create --async --description-format 'Run %{command} (%{template_name})' --inputs command='date' --job-template '$job_template_ansible_default' --search-query 'name ~ container'"
j $logs/56-rex-date-ansible.log
s $wait_interval

skip_measurement='true' h 57-rex-sm-facts-update.log "job-invocation create --async --description-format 'Run %{command} (%{template_name})' --inputs command='subscription-manager facts --update' --job-template '$job_template_ssh_default' --search-query 'name ~ container'"
j $logs/57-rex-sm-facts-update.log
s $wait_interval

skip_measurement='true' h 58-rex-uploadprofile.log "job-invocation create --async --description-format 'Run %{command} (%{template_name})' --inputs command='dnf uploadprofile --force-upload' --job-template '$job_template_ssh_default' --search-query 'name ~ container'"
j $logs/58-rex-uploadprofile.log
s $wait_interval


section "Misc simple tests"
ap 61-hammer-list.log playbooks/tests/hammer-list.yaml
e HammerHostList $logs/61-hammer-list.log
s $wait_interval
rm -f /tmp/status-data-webui-pages.json
skip_measurement='true' ap 62-webui-pages.log \
  -e "ui_pages_concurrency=$ui_pages_concurrency" \
  -e "ui_pages_duration=$ui_pages_duration" \
  playbooks/tests/webui-pages.yaml
STATUS_DATA_FILE=/tmp/status-data-webui-pages.json e WebUIPagesTest_c${ui_pages_concurrency}_d${ui_pages_duration} $logs/62-webui-pages.log
s $wait_interval
a 63-foreman_inventory_upload-report-generate.log satellite6 \
  -m "shell" \
  -a "export organization_id={{ sat_orgid }}; export target=/var/lib/foreman/red_hat_inventory/generated_reports/; /usr/sbin/foreman-rake rh_cloud_inventory:report:generate"
s $wait_interval


section "BackupTest"
skip_measurement='true' ap 70-backup.log playbooks/tests/sat-backup.yaml
e BackupOffline $logs/70-backup.log
e RestoreOffline $logs/70-backup.log
e BackupOnline $logs/70-backup.log
e RestoreOnline $logs/70-backup.log


section "Sync yum repo"
ap 80-test-sync-repositories.log \
  -e "test_sync_repositories_count=$test_sync_repositories_count" \
  -e "test_sync_repositories_url_template=$test_sync_repositories_url_template" \
  -e "test_sync_repositories_max_sync_secs=$test_sync_repositories_max_sync_secs" \
  playbooks/tests/sync-repositories.yaml

e SyncRepositories $logs/80-test-sync-repositories.log
e PublishContentViews $logs/80-test-sync-repositories.log
e PromoteContentViews $logs/80-test-sync-repositories.log


section "Sync iso"
ap 81-test-sync-iso.log \
  -e "test_sync_iso_count=$test_sync_iso_count" \
  -e "test_sync_iso_url_template=$test_sync_iso_url_template" \
  -e "test_sync_iso_max_sync_secs=$test_sync_iso_max_sync_secs" \
  playbooks/tests/sync-iso.yaml

e SyncRepositories $logs/81-test-sync-iso.log
e PublishContentViews $logs/81-test-sync-iso.log
e PromoteContentViews $logs/81-test-sync-iso.log


section "Sync docker repo"
ap 82-test-sync-docker.log \
  -e "test_sync_docker_count=$test_sync_docker_count" \
  -e "test_sync_docker_url_template=$test_sync_docker_url_template" \
  -e "test_sync_docker_max_sync_secs=$test_sync_docker_max_sync_secs" \
  playbooks/tests/sync-docker.yaml

e SyncRepositories $logs/82-test-sync-docker.log
e PublishContentViews $logs/82-test-sync-docker.log
e PromoteContentViews $logs/82-test-sync-docker.log


section "Sosreport"
ap sosreporter-gatherer.log playbooks/satellite/sosreport_gatherer.yaml \
  -e "sosreport_gatherer_local_dir='../../$logs/sosreport/'"


junit_upload
