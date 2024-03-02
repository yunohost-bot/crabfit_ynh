#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================
export nodejs_version="18"

#=================================================
# PERSONAL HELPERS
#=================================================
function build_backend
{
	ynh_script_progression --message="Building crabfit backend..." --weight=1

	# The cargo version packaged with debian (currently 11) is too old and results in errors..
	# Thus the latest version is manually installed alongside the application for the moment
	pushd $install_dir/api
		# The API port is currently hard-coded instead of being in a .env
		# TODO: MR to the upstream
		# In the meantime, lets do some sed!
		sed -i "s/3000/$port_api/g" src/main.rs

		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
		ynh_exec_warn_less ynh_exec_as "$app" \
			RUSTUP_HOME=$install_dir/api/.rustup \
			CARGO_HOME=$install_dir/api/.cargo \
			sh rustup.sh -y -q --no-modify-path --default-toolchain=stable
		export PATH="$PATH:$install_dir/.cargo/bin"
		ynh_exec_warn_less ynh_exec_as "$app" \
			RUSTUP_HOME=$install_dir/api/.rustup \
			CARGO_HOME=$install_dir/api/.cargo \
			$install_dir/api/.cargo/bin/cargo build --release --features sql-adaptor

		# Remove build files and rustup
		ynh_secure_remove --file="$install_dir/api/.cargo"
		ynh_secure_remove --file="$install_dir/api/.rustup"
	popd
}

function build_frontend
{
	ynh_script_progression --message="Building crabfit frontend..." --weight=1
	pushd $install_dir/frontend
		# Paths are currently absolute, which breaks having a /api/ path prefix
		# TODO: MR to the upstream
		sed -i "s/\/event/event/g" $install_dir/frontend/src/config/api.ts
		sed -i "s/\/stats/stats/g" $install_dir/frontend/src/config/api.ts

		ynh_exec_warn_less env "$ynh_node_load_PATH" $nodejs_path/corepack enable
		ynh_exec_warn_less ynh_exec_as "$app" env "$ynh_node_load_PATH" $nodejs_path/yarn install --production --frozen-lockfile
		ynh_exec_warn_less ynh_exec_as "$app" env "$ynh_node_load_PATH" $ynh_npm run build
	popd
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
