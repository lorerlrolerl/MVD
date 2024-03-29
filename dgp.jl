struct Params
	N::Int64
	K1::Int64
	K2::Int64
	V1::Int64
	V2::Int64
	Α_vec::Vector{Float64}
	Α::Matrix{Float64}
	Θ_vec::Matrix{Float64}
	Θ::Vector{Matrix{Float64}}
	η1::Matrix{Float64}
	η2::Matrix{Float64}
	ϕ1::Matrix{Float64}
	ϕ2::Matrix{Float64}
end

function create_Alpha(K1::Int64, K2::Int64, R::Float64,mode::String, s_::Float64)
	if mode == "uni"
		res, Res = create_Alpha_unidiag(K1, K2, R, s_)
		return res, Res
	else
		res,Res = create_Alpha_bidiag(K1, K2, R, s_)
    	return res, Res
	end
end

function create_Alpha_unidiag(K1::Int64, K2::Int64, R::Float64, s_::Float64)

	@assert K1 == K2
	Res = zeros(Float64, (K1, K2))

	off_diag = 1e-20
	if R == 0.99
		for i in 1:K1
			Res[i,i] = 1.0
			for j in 1:K1
				if j != i
					Res[i,j] = off_diag
				end
			end
		end
		Res ./= sum(Res)
		Res .*= s_
	else
		off_diag = (1.0-R)/(R*(K1-1.0))
		for i in 1:K1
			Res[i,i] = 1.0
			for j in 1:K1
				if j != i
					Res[i,j] = off_diag
				end
			end
		end
		Res ./= sum(Res)
		Res .*= s_
	end
	res = vectorize_mat(Res)
    return res, Res
end
function create_Alpha_bidiag(K1::Int64, K2::Int64, R::Float64, s_::Float64)

	@assert K1 == K2
	Res = zeros(Float64, (K1, K2))

	off_diag = 1e-20
	if R == 0.99

		off_diag = 1e-20
		for i in 1:K1
			diagind(Res,1)
			Res[collect(diagind(Res,-1))] .= 1.0
			Res[collect(diagind(Res,1))] .= 1.0
			Res[K1,1] = 1.0;Res[1,K1] = 1.0;
		end
		Res
		Res[Res .!= 1.0] .= off_diag
		Res ./= sum(Res)
		Res .*= s_
	else
		off_diag = 2.0*(1.0-R)/(R*(K1-2.0))
		for i in 1:K1
			diagind(Res,1)
			Res[collect(diagind(Res,-1))] .= 1.0
			Res[collect(diagind(Res,1))] .= 1.0
			Res[K1,1] = 1.0;Res[1,K1] = 1.0;
		end
		Res
		Res[Res .!= 1.0] .= off_diag
		Res ./= sum(Res)
		Res .*= s_
	end
	res = vectorize_mat(Res)
    return res, Res
end
function create_Theta(vec::Vector{Float64}, N::Int64, K1::Int64, K2::Int64)
	res = rand(Distributions.Dirichlet(vec),N)
	Res = [permutedims(reshape(res[:,i], (K2,K1)), (2,1)) for i in 1:N]
    return permutedims(res, (2, 1)), Res
end


function create_ϕ(η_prior::Matrix{Float64}, K::Int64, V::Int64)
	ϕ = zeros(Float64, (K, V))
	for k in 1:K
		ϕ[k,:] = rand(Dirichlet(η_prior[k,:]))
	end
    return ϕ
end

function create_doc(wlen::Int64, topic_dist_vec::Vector{Float64},
	                term_topic_dist::Matrix{Float64}, mode_::Int64,
					K1::Int64, K2::Int64)
	doc = Int64[]
	for w in 1:wlen

		topic_temp = rand(Distributions.Categorical(topic_dist_vec))
		x = zeros(Int64, K1*K2)
		x[topic_temp] = 1
		X = matricize_vec(x, K1, K2)
		where_ = findall(x -> x == 1, X)[1]
		row, col = where_.I
		topic = mode_ == 1 ? row : col
		term = rand(Distributions.Categorical(term_topic_dist[topic,:]))
		doc = vcat(doc, term)
	end
	return doc
end
function create_corpux(N::Int64, vec_list::Matrix{Float64}, ϕ::Matrix{Float64},
	 				   K1::Int64, K2::Int64, wlens::Vector{Int64}, mode_::Int64)

	corpus = [Int64[] for i in 1:N]
	for i in 1:N

		doc  = create_doc(wlens[i], vec_list[i,:] ,ϕ, mode_, K1, K2)
		corpus[i] = vcat(corpus[i], doc)
	end
	return corpus
end

function Create_Truth(N, K1, K2, V1, V2,η1_single, η2_single, wlen1_single, wlen2_single, R, mode, s_)

	# α, Α = manual ? create_Alpha_manual(K1, K2,prior,c) : create_Alpha(K1, K2,prior)
	α,Α = create_Alpha(K1, K2,R,mode,s_)
	θ,Θ = create_Theta(α, N, K1, K2)
	η1 = ones(Float64, (K1, V1)) .* η1_single
	ϕ1 = create_ϕ(η1, K1, V1)
	η2 = ones(Float64, (K2, V2)) .* η2_single
	ϕ2 = create_ϕ(η2, K2, V2)
	wlens1 = [wlen1_single for i in 1:N]
	wlens2 = [wlen2_single for i in 1:N]
	corp1 = create_corpux(N, θ, ϕ1,K1,K2, wlens1, 1)
	corp2 = create_corpux(N, θ, ϕ2,K1,K2, wlens2, 2)
	return α,Α, θ,Θ, ϕ1, ϕ2, η1, η2, V1, V2, corp1, corp2
end


function simulate_data(N, K1, K2, V1, V2,η1_single_truth, η2_single_truth,wlen1_single, wlen2_single, R,mode,s_)
	y1 = Int64[]
 	y2 = Int64[]
	count_tries = 0
 	while true
		count_tries += 1
		if count_tries > 2000
			println("tried a lot, not good params!")
			return 
		end
		α_truth,Α_truth, θ_truth,Θ_truth,
 		ϕ1_truth, ϕ2_truth, η1_truth, η2_truth,V1, V2, corp1, corp2 =
 		Create_Truth(N, K1, K2, V1, V2,η1_single_truth, η2_single_truth, wlen1_single, wlen2_single, R,mode,s_)
		for i in 1:N
			# global y1, y2
         	y1 = unique(y1)
 		  	y2 = unique(y2)
 		    y1 = vcat(y1, corp1[i])
 		    y2 = vcat(y2, corp2[i])
 		end
 		y1 = unique(y1)
 		y2 = unique(y2)
 		if ((length(y1) == V1) && (length(y2) == V2))
             return α_truth,Α_truth, θ_truth,Θ_truth,ϕ1_truth, ϕ2_truth, η1_truth, η2_truth,V1, V2, corp1, corp2
 		else
         	y1 = Int64[]
         	y2 = Int64[]
		end
	 end
end
print("");
