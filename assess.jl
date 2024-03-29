function read_model(eee)
	@load "model_at_epoch_$(eee)" model
	return model
end
function do_ϕs(model)
	ϕ1_est = mean_dir_by_row(model._λ1);
	ϕ2_est = mean_dir_by_row(model._λ2);
	theta_est = mean_dir(model._γ);
	ϕ1_truth = deepcopy(Truth_Params.ϕ1);
	ϕ2_truth = deepcopy(Truth_Params.ϕ2);
	theta_truth = deepcopy(Truth_Params.Θ);

	l = collect(1:size(ϕ1_truth,1));
	m = 1000000.0;
	for i in 1:length(l)
		for j in 1:length(l)
			val = sqrt(sum( (ϕ1_truth[i,:] .- ϕ1_est[j,:]).^2))
			if val < m
				m = val
				l[i] = j
			end
		end
		m=1000000.0
	end
	inds1 = deepcopy(l);
	l = collect(1:size(ϕ2_truth,1));
	m = 1000000.0;
	for i in 1:length(l)
		for j in 1:length(l)
			val = sqrt(sum( (ϕ2_truth[i,:] .- ϕ2_est[j,:]).^2))
			if val < m
				m = val
				l[i] = j
			end
		end
		m=1000000.0
	end
	inds2 = deepcopy(l);
	println(inds1);
	println(inds2);
	#####Something to Consider
	# for i in absent_map
	#    x = deepcopy(theta_est[i])
	#    x[x .<=0.05] .= 1e-2
	#    x./=sum(x)
	#    theta_est[i] .= deepcopy(x)
   # end

	#####
	return theta_est,ϕ1_est, ϕ2_est, ϕ1_truth, ϕ2_truth,theta_truth, inds1, inds2
end

function do_plots(model,theta_est, ϕ1_est, ϕ2_est, ϕ1_truth, ϕ2_truth, theta_truth,inds1, inds2)

	if length(unique(inds1)) == length(inds1) && length(unique(inds2)) == length(inds2)
		p1b = Plots.heatmap(ϕ1_truth, yflip=true)
		p1a = Plots.heatmap(ϕ1_est, yflip=true)
		p2b = Plots.heatmap(ϕ2_truth, yflip=true)
		p2a = Plots.heatmap(ϕ2_est, yflip=true)
		p1a = Plots.heatmap(ϕ1_est[inds1,:], yflip=true)
		p2a = Plots.heatmap(ϕ2_est[inds2,:], yflip=true)
		plot(p1a, p2a, p1b, p2b, layout =(2, 2), legend=false)
		savefig("pics/phis.png")
		theta_truth_1 = zeros(Float64, (length(theta_truth), size(ϕ1_truth,1)));
		for i in 1:size(theta_truth_1,1)
			for j in 1:length(inds1)
				theta_truth_1[i,j] = sum(theta_truth[i][j,:])
			end
		end
		theta_truth_2 = zeros(Float64, (length(theta_truth), size(ϕ2_truth,1)));
		for i in 1:size(theta_truth_2,1)
			for j in 1:length(inds2)
				theta_truth_2[i,j] = sum(theta_truth[i][:,j])
			end
		end

		theta_est_1 = zeros(Float64, (length(theta_truth), size(ϕ1_truth,1)));
		theta_est_2 = zeros(Float64, (length(theta_truth), size(ϕ2_truth,1)));


		for i in 1:size(theta_est_1,1)
			for j in 1:size(ϕ1_truth,1)
				theta_est_1[i,j] = sum(theta_est[i][inds1[j],:])
			end
		end
		for i in 1:size(theta_est_2,1)
			for j in 1:size(ϕ2_truth,1)
				theta_est_2[i,j] = sum(theta_est[i][:,inds2[j]])
			end
		end
		x = collect(range(0.0, 1.0, length=100));
		y = collect(range(0.0, 1.0, length=100));
		@load "h_map" h_map
		plts = [];
		for k in 1:size(ϕ1_est[inds1,:],1)
			p = scatter(theta_truth_1[:,k], theta_est_1[:,k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds1) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds1),2)), legend=false)
			savefig("pics/thetas1.png")
		else
			Plots.plot(plts..., layout =(1, size(ϕ1_est,1)), legend=false)
			savefig("pics/thetas1.png")
		end
		plts = [];
		for k in 1:length(inds1)
			p = scatter(theta_truth_1[.!(h_map),k], theta_est_1[.!(h_map),k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds1) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds1),2)), legend=false)
			savefig("pics/thetas1_train.png")
		else
			Plots.plot(plts..., layout =(1, length(inds1)), legend=false)
			savefig("pics/thetas1_train.png")
		end
		plts = [];
		for k in 1:length(inds1)
			p = scatter(theta_truth_1[h_map,k], theta_est_1[h_map,k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds1) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds1),2)), legend=false)
			savefig("pics/thetas1_ho.png")
		else
			Plots.plot(plts..., layout =(1, length(inds1)), legend=false)
			savefig("pics/thetas1_ho.png")
		end



		plts = [];
		for k in 1:length(inds2)
			p = scatter(theta_truth_2[:,k], theta_est_2[:,k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds2) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds2),2)), legend=false)
			savefig("pics/thetas2.png")
		else
			Plots.plot(plts..., layout =(1, length(inds2)), legend=false)
			savefig("pics/thetas2.png")
		end
		plts = [];
		for k in 1:length(inds2)
			p = scatter(theta_truth_2[.!(h_map),k], theta_est_2[.!(h_map),k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds2) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds2),2)), legend=false)
			savefig("pics/thetas2_train.png")
		else
			Plots.plot(plts..., layout =(1, length(inds2)), legend=false)
			savefig("pics/thetas2_train.png")
		end
		plts = [];
		for k in 1:length(inds2)
			p = scatter(theta_truth_2[h_map,k], theta_est_2[h_map,k],markersize = 1,
           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
			plts = vcat(plts, p)
		end
		if length(inds2) % 2 == 0
			Plots.plot(plts..., layout =(2, div(length(inds2),2)), legend=false)
			savefig("pics/thetas2_ho.png")
		else
			Plots.plot(plts..., layout =(1, length(inds2)), legend=false)
			savefig("pics/thetas2_ho.png")
		end
		absent_map = [i for i in collect(1:length(model._corpus1._docs))[.!h_map] if model._corpus2._docs[i]._length  == 0]
		if !isempty(absent_map)
			present_map = [i for i in collect(1:length(model._corpus1._docs))[.!h_map] if model._corpus2._docs[i]._length != 0]
			plts = [];
			for k in 1:length(inds2)
				p = scatter(theta_truth_2[present_map,k], theta_est_2[present_map,k],markersize = 1,
	           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
				plts = vcat(plts, p)
			end
			if length(inds2) % 2 == 0
				Plots.plot(plts..., layout =(2, div(length(inds2),2)), legend=false)
				savefig("pics/thetas2_present.png")
			else
				Plots.plot(plts..., layout =(1, length(inds2)), legend=false)
				savefig("pics/thetas2_present.png")
			end


			plts = [];
			for k in 1:length(inds2)
				p = scatter(theta_truth_2[absent_map,k], theta_est_2[absent_map,k],markersize = 1,
	           markercolor = :green, grid=false, aspect_ratio=:equal,legend=false);plot!(x, y, linewidth=3);
				plts = vcat(plts, p)
			end
			if length(inds2) % 2 == 0
				Plots.plot(plts..., layout =(2, div(length(inds2),2)), legend=false)
				savefig("pics/thetas2_absent.png")
			else
				Plots.plot(plts..., layout =(1, length(inds2)), legend=false)
				savefig("pics/thetas2_absent.png")
			end
		end
		p1 = Plots.heatmap(model._α[inds1, inds2])
		savefig("pics/model_Alpha.png")
		p2 = Plots.heatmap(Truth_Params.Α)
		savefig("pics/true_Alpha.png")
		return theta_truth_1,theta_truth_2,theta_est_1,theta_est_2
	else
		return nothing, nothing, nothing, nothing
	end
end
