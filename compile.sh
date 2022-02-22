#!/bin/bash
 
echo "compile.sh"
# mkdir -p ${result_folder}/folder1
# mkdir -p ${result_folder}/folder2
# mkdir -p ${result_folder}/folder1/folder11
# echo "123" >> ${result_folder}/folder1/folder11/test11.txt
# echo "123" >> ${result_folder}/folder1/test1.txt
# echo "123" >> ${result_folder}/folder2/test2.txt
# cp -r ${data_folder} ${result_folder}/

echo "checking out source code"
git clone https://github.com/NCAR/wrf_hydro_nwm_public.git ${executable_folder}/WRFHYDRO
cd ${executable_folder}/WRFHYDRO && git checkout ${param_git_branch_tag_commit}

echo "compiling"
echo "copying setEnvar.sh"
cp ${executable_folder}/WRFHYDRO/trunk/NDHMS/template/setEnvar.sh ${executable_folder}/WRFHYDRO/trunk/NDHMS/
setEnvar=${data_folder}/setEnvar.sh
if [[ -f "${setEnvar}" ]]; then
    echo "setEnvar.sh provided by user. overwriting..."
    cp  ${data_folder}/setEnvar.sh ${executable_folder}/WRFHYDRO/trunk/NDHMS/
fi
chmod +x ${executable_folder}/WRFHYDRO/trunk/NDHMS/setEnvar.sh


cd ${executable_folder}/WRFHYDRO/trunk/NDHMS
chmod +x ./configure
./configure 2
chmod +x ./compile_offline_NoahMP.sh
chmod +x ./compile_offline_Noah.sh
if [ -z "${param_lsm}" ]; then
  echo "ENV parm_lsm Not Set; Default to NoahMP"
  param_lsm="NoahMP"
fi

if [[ "${param_lsm}" != "NoahMP" && "${param_lsm}" != "Noah" ]]; then
  echo "ENV parm_lsm Value Unknown; Default to NoahMP"
  param_lsm="NoahMP"
fi
echo "param_lsm: ${param_lsm}"

echo "running: ./compile_offline_${param_lsm}.sh setEnvar.sh"
./compile_offline_${param_lsm}.sh setEnvar.sh
ls ${executable_folder}/WRFHYDRO/trunk/NDHMS/Run -al

echo "setting up simulation folder"
mkdir -p ${result_folder}/Simulation


echo "setting symbolic links to Domain and Forcing"
ln -sf ${data_folder}/FORCING ${result_folder}/Simulation
ln -sf ${data_folder}/DOMAIN ${result_folder}/Simulation
restart_folder=${data_folder}/RESTART
if [[ -d "${restart_folder}" ]]; then
    ln -sf ${data_folder}/RESTART  ${result_folder}/Simulation
fi

echo "copying compiled binary and static files from Run/* to Simulation/"
cp -rf ${executable_folder}/WRFHYDRO/trunk/NDHMS/Run/* ${result_folder}/Simulation/

echo "copying namelist.hrldas from repo"
namelist_hrldas=${data_folder}/namelist.hrldas
if [[ -f "${namelist_hrldas}" ]]; then
    echo "namelist.hrldas provided by user. overwriting..."
    cp  ${data_folder}/namelist.hrldas  ${result_folder}/Simulation
fi

echo "copying hydro.namelist from repo"
hydro_namelist=${data_folder}/hydro.namelist
if [[ -f "${hydro_namelist}" ]]; then
    echo "hydro.namelist provided by user. overwriting..."
    cp  ${data_folder}/hydro.namelist  ${result_folder}/Simulation
fi


ls ${data_folder}/DOMAIN ${result_folder}/Simulation -al
