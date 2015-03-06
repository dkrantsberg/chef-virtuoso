#
# Cookbook Name:: virtuoso
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#include_recipe 'git'

code_user=node['virtuoso']['code_user']
code_group=node['virtuoso']['code_group']
code_dir=node['virtuoso']['code_dir']
install_dir=node['virtuoso']['install_dir']


['autoconf','automake','libtool','flex','bison','gperf','gawk','m4','make','openssl-devel','readline-devel'].each do |pkg|
	package pkg do
		action :install
	end
end


git code_dir do
  repository "git://github.com/openlink/virtuoso-opensource.git"
  revision node['virtuoso']['revision']
  user code_user
  group code_group
  action :sync
end

bash 'compile' do
  user code_user
  group code_group
  cwd code_dir
  environment ({'CFLAGS' => node['virtuoso']['cflags']})
  code <<-EOH
    ./autogen.sh
    ./configure --prefix="#{install_dir}" --program-transform-name="s/isql/isql-vt/" --with-readline
    make
  EOH
  action :run
  notifies :run, "execute[install]"
end
	
execute "install" do
  cwd code_dir
  command 'make install'
  action :nothing
  notifies :run, "bash[add to /usr/bin]"
end
	
bash "add to /usr/bin" do
  code <<-EOH
    ln -s -f #{install_dir}/bin/virtuoso-t /usr/local/bin/virtuoso-t
    ln -s -f #{install_dir}/bin/isql-vt /usr/local/bin/isql-vt
   EOH
  action :nothing
  notifies :run, "bash[start]"
end

  
template "inifile" do
	path "#{install_dir}/var/lib/virtuoso/db/virtuoso.ini"
	source "virtuoso.ini.erb"
	owner  code_user
	mode "0755"
	action :create
	notifies :run, "bash[start]"
end

bash "start" do
  user code_user
  group code_group
  code <<-EOH
	virtuoso-t -c #{install_dir}/var/lib/virtuoso/db/virtuoso.ini
  EOH
  action :nothing
end