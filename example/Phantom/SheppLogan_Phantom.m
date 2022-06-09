
% Shepp-Logan phantom (256 matrix) if 128 change lines 5 and l18

% generate a Shepp-Logan susceptibility distribution 
shepplogan_sus_dist = SheppLogan( 256, [0.36e-6 -8.842e-6 -4.759e-6 1.842e-6]);
%shepplogan_sus_dist = SheppLogan( 256, [a b c d]);
% save as nifti
shepplogan_sus_dist.save('Shepp_Logan_ChiDist.nii');


% compute deltaB0 for the simulated susceptibility distribution using:
shepplogan_dBz = FBFest(shepplogan_sus_dist.volume, shepplogan_sus_dist.image_res, shepplogan_sus_dist.matrix);
% save as nifti
shepplogan_dBz.save('Bdz_shepplogan_ChiDist.nii');


% simulate T2* decay for a cylinder of air surrounded by mineral oil with a
% deltaB0 found in an external file
shepplogan_vol = NumericalModel('Shepp-Logan3d',256);
shepplogan_vol.generate_deltaB0('load_external', 'Bdz_shepplogan_ChiDist.nii');
shepplogan_vol.simulate_measurement(15, [0.001 0.002 0.003 0.004 0.005 0.006], 100);


% get magnitude and phase data
magn = shepplogan_vol.getMagnitude;
phase = shepplogan_vol.getPhase;
compl_vol = magn.*exp(1i*phase);

% calculate the deltaB0 map from the magnitude and phase data
[dual_echo_delf] = +imutils.b0.dual_echo(compl_vol(:,:,:,1:2), [0.001 0.002]);
[multi_echo_delf] = +imutils.b0.multiecho_linfit(compl_vol, [0.001 0.002 0.003 0.004 0.005 0.006]); 

dual_echo_b0_ppm = 1e6*(dual_echo_delf/3)*(1/42.58e6);
multi_echo_b0_ppm = 1e6*(multi_echo_delf/3)*(1/42.58e6);

% save b0 maps
nii_vol = make_nii(dual_echo_b0_ppm);
save_nii(nii_vol, ['dualechoB0_ppm_spheppLogan' '.nii']);

nii_vol = make_nii(multi_echo_b0_ppm);
save_nii(nii_vol, ['multiechoB0_ppm_spheppLogan' '.nii']);

% % plot results
% figure; imagesc(squeeze(multi_echo_b0_ppm(:,:,64))); colorbar
% title('multi-echo fit: b0 (ppm)')
% 
% figure; imagesc(squeeze(dual_echo_b0_ppm(:,:,64))); colorbar; 
% title('dual-echo fit: b0 (ppm)')
% 
% figure; imagesc(squeeze(1e6.*real(shepplogan_dBz.volume(:,:,64)))); colorbar;
% title('Fourier-based field estimation for the modified Shepp-Logan phantom: b0 (ppm)')
% 
% % calc diff between dual-echo and multi-echo
% diff_dualecho = (dual_echo_b0_ppm-1e6.*real(shepplogan_dBz.volume));
% figure; imagesc(squeeze(diff_dualecho(:,:,64))); colorbar; title('dual echo - true dBz');
% 
% diff_multiecho = (multi_echo_b0_ppm-1e6.*real(shepplogan_dBz.volume));
% figure; imagesc(squeeze(diff_multiecho(:,:,64))); colorbar; title('multi echo - true dBz');



