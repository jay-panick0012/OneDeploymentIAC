#!/usr/bin/env bash
###############################################################################
# scripts/new-region.sh
#
# Scaffolds a new environments/<env>/<cloud>/<region>/ root by copying an
# existing region directory of the same environment+cloud (so it inherits the
# right tier sizing) and rewriting the region/location and backend key. It
# does NOT pick a region_index for you -- open .github/region-matrix.json,
# find the highest region_index in use across the WHOLE file, and pass the
# next integer. Reusing an index will collide CIDR ranges with another
# region's VPC/VNet.
#
# Usage:
#   scripts/new-region.sh <environment> <cloud> <new-region> <region-index>
#
# Example:
#   scripts/new-region.sh production aws ap-south-1 5
###############################################################################

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <environment> <cloud> <new-region> <region-index>" >&2
  echo "Example: $0 production aws ap-south-1 5" >&2
  exit 1
fi

environment="$1"
cloud="$2"
new_region="$3"
region_index="$4"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_cloud_dir="${repo_root}/environments/${environment}/${cloud}"

if [[ ! -d "$env_cloud_dir" ]]; then
  echo "error: ${env_cloud_dir} does not exist -- is '${environment}'/'${cloud}' correct?" >&2
  exit 1
fi

template_region="$(find "$env_cloud_dir" -mindepth 1 -maxdepth 1 -type d | head -n1 | xargs -n1 basename)"
if [[ -z "$template_region" ]]; then
  echo "error: no existing region directory to copy under ${env_cloud_dir}" >&2
  exit 1
fi

target_dir="${env_cloud_dir}/${new_region}"
if [[ -d "$target_dir" ]]; then
  echo "error: ${target_dir} already exists" >&2
  exit 1
fi

echo "Copying ${env_cloud_dir}/${template_region} -> ${target_dir}"
cp -r "${env_cloud_dir}/${template_region}" "$target_dir"

# Location/region variable is called "region" for aws/gcp, "location" for azure.
var_name="region"
[[ "$cloud" == "azure" ]] && var_name="location"

for f in "$target_dir/terraform.tfvars" "$target_dir/variables.tf"; do
  sed -i.bak \
    -e "s/${template_region}/${new_region}/g" \
    -e "s/region_index[[:space:]]*=[[:space:]]*[0-9]\+/region_index = ${region_index}/" \
    "$f"
  rm -f "${f}.bak"
done

sed -i.bak "s#environments/${environment}/${cloud}/${template_region}#environments/${environment}/${cloud}/${new_region}#g" \
  "$target_dir/backend.hcl"
rm -f "$target_dir/backend.hcl.bak"

cat <<EOF

Created ${target_dir} from the ${template_region} template.

Next steps:
  1. Double-check ${target_dir}/terraform.tfvars and backend.hcl -- region
     names sometimes appear inside other strings (e.g. a bucket name) that
     this script's find/replace may not catch.
  2. Add this region to .github/region-matrix.json under
     "${environment}" -> "${cloud}", with the same region_index (${region_index}).
  3. cd ${target_dir} && terraform init -backend-config=backend.hcl && terraform plan -var-file=terraform.tfvars
EOF
