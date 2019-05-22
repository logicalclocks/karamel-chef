
hopsUtilpyTestArtifactsDirUrl = "http://snurran.sics.se/hops/hops-util-py_test"
hopsUtilpyTestArtifactsDirHdfs = "/user/it_tests"
hopsUtilpyTestData1Name = "attendances_features.csv"
hopsUtilpyTestData1Url = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestData1Name}"
hopsUtilpyTestData2Name = "games_features.csv"
hopsUtilpyTestData2Url = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestData2Name}"
hopsUtilpyTestData3Name = "players_features.csv"
hopsUtilpyTestData3Url = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestData3Name}"
hopsUtilpyTestData4Name = "season_scores_features.csv"
hopsUtilpyTestData4Url = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestData4Name}"
hopsUtilpyTestData5Name = "teams_features.csv"
hopsUtilpyTestData5Url = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestData5Name}"
hopsUtilpyTestDataNotebookName = "integration_tests.ipynb"
hopsUtilpyTestDataNotebookUrl = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestDataNotebookName}"
hopsUtilpyTestDataSkLearnModelName = "iris_knn.pkl"
hopsUtilpyTestDataSkLearnModelUrl = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestDataSkLearnModelName}"
hopsUtilpyTestDataSkLearnModelScriptName = "iris_flower_classifier.py"
hopsUtilpyTestDataSkLearnModelScriptUrl = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestDataSkLearnModelScriptName}"
hopsUtilpyTestDataTfModelZipName = "mnist.tar.gz"
hopsUtilpyTestDataTfModelUrl = "#{hopsUtilpyTestArtifactsDirUrl}/#{hopsUtilpyTestDataTfModelZipName}"
hopsUtilpyTestDataTfModelDir = "mnist"


hops_hdfs_directory "#{hopsUtilpyTestArtifactsDirHdfs}" do
  action :create_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1777"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData1Name)}" do
  source hopsUtilpyTestData1Url
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData1Name)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestData1Name}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData2Name)}" do
  source hopsUtilpyTestData2Url
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData2Name)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestData2Name}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData3Name)}" do
  source hopsUtilpyTestData3Url
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData3Name)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestData3Name}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData4Name)}" do
  source hopsUtilpyTestData4Url
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData4Name)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestData4Name}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData5Name)}" do
  source hopsUtilpyTestData5Url
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestData5Name)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestData5Name}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataNotebookName)}" do
  source hopsUtilpyTestDataNotebookUrl
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataNotebookName)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestDataNotebookName}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataSkLearnModelName)}" do
  source hopsUtilpyTestDataSkLearnModelUrl
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataSkLearnModelName)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestDataSkLearnModelName}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataSkLearnModelScriptName)}" do
  source hopsUtilpyTestDataSkLearnModelScriptUrl
  owner 'hdfs'
  group 'hadoop'
  mode "1775"
  action :create
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataSkLearnModelScriptName)}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestDataSkLearnModelScriptName}"
end

remote_file "#{Chef::Config['file_cache_path']}/#{File.basename(hopsUtilpyTestDataTfModelZipName)}" do
  source hopsUtilpyTestDataTfModelUrl
  mode 0755
  action :create
end

# Extract Model Zip
bash 'extract_mnist_model' do
  user "root"
  code <<-EOH
                set -e
                cd #{Chef::Config['file_cache_path']}
                rm -rf #{hopsUtilpyTestDataTfModelDir}
                tar -zxf #{hopsUtilpyTestDataTfModelZipName}
                chown -RL hdfs:hadoop #{Chef::Config['file_cache_path']}/#{hopsUtilpyTestDataTfModelDir}
  EOH
end

hops_hdfs_directory "/user/it_tests/#{hopsUtilpyTestDataTfModelDir}" do
  action :create_as_superuser
  owner node['hops']['hdfs']['user']
  group node['hops']['group']
  mode "1775"
end

hops_hdfs_directory "#{Chef::Config['file_cache_path']}/#{hopsUtilpyTestDataTfModelDir}" do
  action :replace_as_superuser
  owner 'hdfs'
  group 'hadoop'
  mode "1755"
  dest "/user/it_tests/#{hopsUtilpyTestDataTfModelDir}"
end