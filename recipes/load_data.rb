install_dir=node['virtuoso']['install_dir']
data_file=node['virtuoso']['data_file']
temp_dir=node['virtuoso']['temp_dir']
graph_iri=node['virtuoso']['graph_iri']

package 'unzip' do
	action :install
end

directory temp_dir do
  action :create
end
cookbook_file data_file do
  path "#{temp_dir}/#{data_file}"
  action :create_if_missing
end

bash 'unzip' do
  cwd temp_dir
  code <<-EOH
    unzip -o #{data_file}
   EOH
  action :run
end

bash 'create_lod_list' do
  cwd temp_dir
  code <<-EOH
    isql-vt #{node['virtuoso']['isql_port']} dba dba exec="ld_dir ('#{temp_dir}', '*.rdf', #{graph_iri}');"
   EOH
  action :run
end

bash 'run_loader' do
  cwd temp_dir
  code <<-EOH
    isql-vt #{node['virtuoso']['isql_port']} dba dba exec="rdf_loader_run();"
   EOH
  action :run
end
