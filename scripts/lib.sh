[ "${GEODESIC_SHELL}" == "true" ] || (echo "This script is intended to be run inside the account container. "; exit 1)

export CONF="${CONF:-/conf}"

function abort() {
	echo -e "\n\n"
	echo "==============================================================================================="
	echo "$1"
	echo
	echo "* Please report this error here:"
	echo "          https://github.com/cloudposse/reference-architectures/issues/new"
	echo -e "\n\n"
	exit 1
}

# Provision modules
function apply_modules() {
	# Provision modules which *do not* have dependencies on other accounts (that will be a later phase)
	for module in ${TERRAFORM_ROOT_MODULES}; do 
		if [[ -n "${SKIP_MODULES}" ]] && [[ "${module}" =~ ${SKIP_MODULES} ]]; then
			echo "Skipping ${module}..."
		else
			echo "Processing $module..."
			direnv exec "/conf/${module}" make -C "/conf/${module}" deps
			direnv exec "/conf/${module}" make -C "/conf/${module}" apply
			if [ $? -ne 0 ]; then
				abort "The ${module} module errored. Aborting."
			fi
		fi
	done
}

# Easily assume role using the "bootstrap" user
function assume_role() {
	echo "Attempting to assume role to ${AWS_DEFAULT_PROFILE}..."

	# Load the environment exported by the `bootstrap` module
	source /artifacts/.envrc

	# Install the helper cli for assuming roles as part of the bootstrapping process
	[ -x /usr/bin/assume-role ] || apk add --update assume-role@cloudposse

	# This is because the [`assume-role`](https://github.com/remind101/assume-role) cli does not respect the SDK environment variables.
	export HOME="/artifacts"
	export AWS_CONFIG_FILE="${HOME}/.aws/config"
	export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/credentials"

	# Unset AWS credential environment variables so they don't interfere with `assume-role`
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCESS_KEY

	# Fetch the Role ARN from the configuration
	export AWS_ASSUME_ROLE_ARN=$(crudini --get ${AWS_CONFIG_FILE} "profile ${AWS_DEFAULT_PROFILE}" role_arn)

	if [ -z "${AWS_ASSUME_ROLE_ARN}" ]; then
		abort "ARN for ${AWS_DEFAULT_PROFILE} not found in ${AWS_CONFIG_FILE}"
	fi

	# Obtain an assume-role session
	eval $(/usr/bin/assume-role $AWS_DEFAULT_PROFILE)
	if [ $? -ne 0 ]; then
		echo "Failed to assume role of ${AWS_DEFAULT_PROFILE}"
		exit 1
	fi
}

# Don't use a role to simplify provisioning of root account
function disable_profile() {
	export TF_VAR_aws_assume_role_arn=""
	unset AWS_DEFAULT_PROFILE
	unset AWS_PROFILE
}

# Export map of accounts
function export_accounts() {
	# Export account ids (for use with provisioning children)
	cd /conf/accounts
	direnv exec . make reset deps
	(
		echo "aws_account_ids = {"
		terraform output -json | jq -r 'to_entries | .[] | .key + " = \"" + .value.value + "\""' | grep account_id | sed 's/_account_id//'
		echo "}"
	) | terraform fmt - > /artifacts/accounts.tfvars
}

# Import env for this stage
function import_env() {
	# Load the environment for this stage, if they exist
	echo "Loading /artifacts/${STAGE}.env"
	source /artifacts/${STAGE}.env

	# Export our environment to TF_VARs
	eval $(tfenv sh -c "export -p")
}

# Plan modules
function plan_modules() {
	# Provision modules which *do not* have dependencies on other accounts (that will be a later phase)
	for module in ${TERRAFORM_ROOT_MODULES}; do 
		if [[ -n "${SKIP_MODULES}" ]] && [[ "${module}" =~ ${SKIP_MODULES} ]]; then
			echo "Skipping ${module}..."
		else
			echo "Processing $module..."
			direnv exec "/conf/${module}" make -C "/conf/${module}" deps
			direnv exec "/conf/${module}" make -C "/conf/${module}" plan
			if [ $? -ne 0 ]; then
				abort "The ${module} module errored. Aborting."
			fi
		fi
	done
}

function parse_args() {
	while [[ $1 ]]; do
		echo "Handling [$1]..."
		case "$1" in
		-a | --assume-role)
			assume_role
			shift
			;;
		-d | --disable-profile)
			disable_profile
			shift
			;;
		-m | --apply-modules)
			apply_modules
			shift
			;;
		-p | --plan-modules)
			plan_modules
			shift
			;;
		-i | --import-env)
			import_env
			shift
			;;
		-e | --export-accounts)
			export_accounts
			shift
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
		esac
	done
}

function ctrl_c() {
	echo "* Okay, aborting..."
	exit 1
}
