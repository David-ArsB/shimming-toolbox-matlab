
% Cylindrical phantom

% generate a cylindrical susceptibility distribution at 90 degrees 
cylindrical_sus_dist = Cylindrical( [128 128 128], [1 1 1], 5, pi/2, [0.36e-6 -8.842e-6]);
% save as nifti
cylindrical_sus_dist.save('cylindrical90_R5mm_airMineralOil_ChiDist.nii');
% save as nifti for different angle between main axis of cylinder and z-axis (in radians)
% cylindrical_sus_dist.save('pi_2_cylindrical_ChiDist.nii');
% cylindrical_sus_dist.save('pi_4_cylindrical_ChiDist.nii');


% compute deltaB0 for the simulated cylindrical susceptibility distribution
cylindrical_dBz = FBFest(cylindrical_sus_dist.volume, cylindrical_sus_dist.image_res, cylindrical_sus_dist.matrix);
% save as nifti
cylindrical_dBz.save('Bdz_cylindrical90_R5mm_airMineralOil_ChiDist');

% simulate T2* decay for a cylinder of air surrounded by mineral oil with a
% deltaB0 found in an external file
cylindrical_vol = NumericalModel('Cylindrical3d',128,1,5,90,'Air', 'pure_mineral_oil');
cylindrical_vol.generate_deltaB0('load_external', 'Bdz_cylindrical90_R5mm_airMineralOil_ChiDist.nii');
cylindrical_vol.simulate_measurement(15, [0.001 0.002 0.003 0.004 0.005 0.006], 100);


% get magnitude and phase data
magn = cylindrical_vol.getMagnitude;
phase = cylindrical_vol.getPhase;
compl_vol = magn.*exp(1i*phase);


% calculate the deltaB0 map from the magnitude and phase data
[dual_echo_delf] = +imutils.b0.dual_echo(compl_vol(:,:,:,1:2), [0.001 0.002]);
[multi_echo_delf] = +imutils.b0.multiecho_linfit(compl_vol, [0.001 0.002 0.003 0.004 0.005 0.006]); 

dual_echo_b0_ppm = 1e6*(dual_echo_delf/3)*(1/42.58e6);
multi_echo_b0_ppm = 1e6*(multi_echo_delf/3)*(1/42.58e6);

% save b0 maps
nii_vol = make_nii(dual_echo_b0_ppm);
save_nii(nii_vol, ['dualechoB0_ppm_cylindrical' '.nii']);

nii_vol = make_nii(multi_echo_b0_ppm);
save_nii(nii_vol, ['multiechoB0_ppm_cylindrical' '.nii']);

% % plot results
% figure
% imagesc(squeeze(multi_echo_b0_ppm(:,:,64)))
% colorbar
% title('multi-echo fit: b0 (ppm)')
% 
% figure
% imagesc(squeeze(dual_echo_b0_ppm(:,:,64)))
% colorbar
% title('dual-echo fit: b0 (ppm)')
% 
% figure
% imagesc(squeeze(1e6.*real(cylindrical_dBz.volume(:,:,64))))
% colorbar
% title('Fourier-based field estimation for the cylinder: b0 (ppm)')
% 
% % calc diff between dual-echo and multi-echo
% diff_dualecho = (dual_echo_b0_ppm-1e6.*real(cylindrical_dBz.volume));
% figure; imagesc(squeeze(diff_dualecho(:,:,64))); colorbar; title('dual echo - true dBz');
% 
% diff_multiecho = (multi_echo_b0_ppm-1e6.*real(cylindrical_dBz.volume));
% figure; imagesc(squeeze(diff_multiecho(:,:,64))); colorbar; title('multi echo - true dBz');
% 
% 
% 

% % save b0 maps
% nii_vol = make_nii(imrotate(fliplr(dual_echo_B0_ppm), -90));
% save_nii(nii_vol, ['dualechoB0_ppm_cylindrical90_R5mm_airMineralOil' '.nii']);
% 
% nii_vol = make_nii(imrotate(fliplr(multi_echo_B0_ppm), -90));
% save_nii(nii_vol, ['multiechoB0_ppm_cylindrical90_R5mm_airMineralOil' '.nii']);

