module Heatbath
    using LinearAlgebra
    import ..LTK_universe:Universe
    import ..Gaugefields:GaugeFields,SU3GaugeFields,
            SU2GaugeFields,SU3GaugeFields_1d,SU2GaugeFields_1d,
            GaugeFields_1d,elementwise_tr!,set_wing!,make_staple_double!,substitute!,clear!,
            evaluate_wilson_loops!,normalize!,normalize3!,normalize2!
    import ..Wilsonloops:Wilson_loop,Wilson_loop_set,make_plaq_staple,make_links,make_staples,make_plaq
    import ..Actions:GaugeActionParam_standard,GaugeActionParam_autogenerator,GaugeActionParam

    function heatbath!(univ::Universe)
        heatbath!(univ.U,univ.ranf,univ.gparam,univ._temporal_gauge)
        #heatbath!(univ.U,univ.ranf,univ.gparam.β,univ._temporal_gauge)
    end

    function heatbath!(u::Array{T,1},ranf,gparam::GaugeActionParam,temps::Array{T_1d,1}) where {T <: SU2GaugeFields,T_1d <: SU2GaugeFields_1d}
        beta = gparam.β

    
        staple= temps[1]
        temp1= temps[2]
        temp2 = temps[3]
        temp3 = temps[4]



        NV = staple.NV
        ITERATION_MAX = 10^5
        
        Wnew = zeros(ComplexF64,2,2)
        NX = u[1].NX
        NY = u[1].NY
        NZ = u[1].NZ
        NT = u[1].NT

        NC = 2
        V = zeros(ComplexF64,NC,NC)
        Vtemp = zeros(ComplexF64,NC,NC)

        a = zeros(Float64,4)

        for mu=1:4
            #make_staple_double!(staple,u,mu,temp1,temp2,temp3)
            if typeof(gparam) == GaugeActionParam_standard
                loops = make_plaq_staple(mu)
            end


            
            
            #for i=1:NV
            i = 0
            for it=1:NT
                for iz=1:NZ
                    for iy=1:NY
                        for ix = 1:NX
                            i += 1 

                            if typeof(gparam) == GaugeActionParam_standard
                                evaluate_wilson_loops!(V,loops,u,ix,iy,iz,it)
                            elseif typeof(gparam) == GaugeActionParam_autogenerator
                                V .= 0
                                Vtemp .= 0
                                for iloop = 1:gparam.numactions
                                    evaluate_wilson_loops!(Vtemp,gparam.staples[iloop][mu],u,ix,iy,iz,it)
                                    @. V += (gparam.βs[iloop]/beta)*Vtemp
                                end
                            end
                            
                            u[mu][:,:,ix,iy,iz,it] = SU2update(V,beta,NC,ITERATION_MAX)

                        end
                    end
                end
            end
            #normalize!(u[mu])
        end

    end

    function SU2update(V,beta,NC,ITERATION_MAX = 10^5)
        R = real(sqrt(det(V)))
        V0 = inv(V/R)

        ρ0 = real(V[1,1]+V[2,2])
        ρ1 = -imag(V[1,2]+V[2,1])
        ρ2 = real(V[2,1]-V[1,2])
        ρ3 = imag(V[2,2]-V[1,1])
        ρ = sqrt(ρ0^2+ρ1^2+ρ2^2+ρ3^2)

        #
        #Nc = 2 # Since Ishikawa's book uses 1/g^2 notation.
        k = (beta/NC)*ρ

        #k = 2beta*R


        #A = 2*sinh(k)
        emk = exp(-k)
        epk = exp(k)
        ur = 999.0
        i_count=0
        a = zeros(Float64,4)
        while(ur^2 > 1.0-a[1]^2) # rejection sampling
            s = rand()
            a[1] = log(s*epk + (1-s)*emk)/k # F.17
            #a[1] =log(A*y+B)/(k)
            ur = rand()
            i_count+=1
            if i_count> ITERATION_MAX
                error("The rejection sampling is failed after $ITERATION_MAX trials.")
            end
        end

        rr = sqrt(1.0-a[1]^2)
        ϕ = rand()*pi*2.0 # ϕ = [0,2pi]
        cosθ = (rand()-0.5)*2.0 # -1<cosθ<1
        sinθ = sqrt(1-cosθ^2)

        a[2]=rr*cos(ϕ)*sinθ
        a[3]=rr*sin(ϕ)*sinθ
        a[4]=rr*cosθ
        Unew = [a[1]+im*a[4] a[3]+im*a[2]
                -a[3]+im*a[2] a[1]-im*a[4]]*V0
        #normalize2!(Unew)
        #display(Unew)

        α = Unew[1,1]
        β = Unew[2,1]
        detU = abs(α)^2 + abs(β)^2
        Unew[1,1] = α/detU
        Unew[2,1]  = β/detU
        Unew[1,2] = -conj(β)/detU
        Unew[2,2] = conj(α)/detU                            

        return Unew
    end

    function heatbath!(u::Array{T,1},ranf,gparam,temps::Array{T_1d,1}) where {T <: SU3GaugeFields,T_1d <: SU3GaugeFields_1d}
        #println("Warning!!!!!!!!")
        error("Heatbath update for SU(3) is not implemented")
        beta = gparam.β

    
        staple= temps[1]
        temp1= temps[2]
        temp2 = temps[3]
        temp3 = temps[4]



        NV = staple.NV
        ITERATION_MAX = 10000
        Wnew = zeros(ComplexF64,2,2)
        NX = u[1].NX
        NY = u[1].NY
        NZ = u[1].NZ
        NT = u[1].NT

        NC = 3
        V = zeros(ComplexF64,NC,NC)
        Vtemp = zeros(ComplexF64,NC,NC)

        a = zeros(Float64,4)

        #=
        for mu=1:4
            normalize!(u[mu])
            set_wing!(u[mu])
        end
        =#

        for mu=1:4
            #make_staple_double!(staple,u,mu,temp1,temp2,temp3)
            if typeof(gparam) == GaugeActionParam_standard
                loops = make_plaq_staple(mu)
            end
            


            
            
            #for i=1:NV
            i = 0
            for it=1:NT
                for iz=1:NZ
                    for iy=1:NY
                        for ix = 1:NX
                            i += 1 

                            if typeof(gparam) == GaugeActionParam_standard
                                evaluate_wilson_loops!(V,loops,u,ix,iy,iz,it)
                            elseif typeof(gparam) == GaugeActionParam_autogenerator
                                V .= 0
                                Vtemp .= 0
                                for iloop = 1:gparam.numactions
                                    evaluate_wilson_loops!(Vtemp,gparam.staples[iloop][mu],u,ix,iy,iz,it)
                                    @. V += (gparam.βs[iloop]/beta)*Vtemp
                                end
                            end

                            #println("#Heatbath for one SU(3) link started")
                            for l=1:3
                                UV = u[mu][:,:,ix,iy,iz,it]*V
                                #normalize3!(SN)
                                #println(SN'*SN)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(U) =  $(det(u[mu][:,:,ix,iy,iz,it])) #SU(3)")
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(V) =  $(det(V)) #prop SU(3)")
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(UV) =  $(det(UV)) #prop SU(3)")

                                if l==1
                                    n,m = 1,2
                                elseif l==2
                                    n,m = 2,3
                                else
                                    n,m = 1,3
                                end
                                S = make_submatrix(UV,n,m)
                                project_onto_SU2!(S)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(S) =  $(det(S)) #prop SU(2)")
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: tr(S) =  $(tr(S)) #prop SU(2)")
                                #println("SU2update: S->K")

                                K = SU2update(S,beta,NC,ITERATION_MAX)

                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(K) =  $(det(K))# before normalize #SU(2)")
                                #K = normalize2!(K)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(K) =  $(det(K))# after normalize #SU(2)")

                                A = make_largematrix(K,n,m,NC)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(A) =  $(det(A)) # before normalize #SU(3)")
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: tr(A) =  $(tr(A)) # before normalize #SU(3)")
                                #normalize3!(A)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(A) =  $(det(A)) # after normalize #SU(3)")
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: tr(A) =  $(tr(A)) # after normalize #SU(3)")
                                #normalize3!(A)
                                AU = A*u[mu][:,:,ix,iy,iz,it]

                                normalize3!(AU)
                                #println("ix,iy,iz,it,l = $ix,$iy,$iz,$it,$l :: det(AU) =  $(det(AU)) #SU(3)\n")
                                u[mu][:,:,ix,iy,iz,it] = AU
                            end

                            #exit()


                        end
                    end
                end
            end
            #normalize!(u[mu])
            set_wing!(u[mu])
        end

    end

    function project_onto_SU2!(S) # This project onto SU(2) up to normalization.
        #S2 = zeros(ComplexF64,2,2)
        α = S[1,1]*0.5 + conj(S[2,2])*0.5
        β = S[2,1]*0.5 - conj(S[1,2])*0.5
        S[1,1] = α
        S[2,1] = β
        S[1,2] = -conj(β)
        S[2,2] = conj(α)
        #return S2
    end

    function make_submatrix(UV,i,j)
        S = zeros(ComplexF64,2,2)
        S[1,1] = UV[i,i]
        S[1,2] = UV[i,j]
        S[2,1] = UV[j,i]
        S[2,2] = UV[j,j]
        return S
    end


    function make_largematrix(K,i,j,NC)
        A = zeros(ComplexF64,NC,NC)
        for n=1:NC
            A[n,n] = 1
        end
        #K = project_onto_su2(K)
        A[i,i] = K[1,1]
        A[i,j] = K[1,2] 
        A[j,i] = K[2,1]
        A[j,j] = K[2,2]  
        return A
    end

    const nhit = 6
    const rwidth = 0.4

    #=
    """
    update3!(params::Parameters,crand_public::Crand,u,beta)
c------------------------------------------------------c
*     pseudo-heat-bath for su3
*     N.Cabbibo and E.Marinari Phys.Lett.119B(1982)387.
*     Kendy-Pendelton
*     This program was originally written by S.Hioki
c------------------------------------------------------c
    """
    function heatbath!(u::Array{T,1},ranf,beta,temps::Array{T_1d,1}) where {T <: SU3GaugeFields,T_1d <: SU3GaugeFields_1d}
        staple= temps[1]
        temp1= temps[2]
        temp2 = temps[3]
        temp3 = temps[4]

        NV = temp1.NV
        NBUSH = 1
        eps = 0.000000000001

        v = zeros(Float64,4,div(NV,NBUSH))
        rn = zeros(Float64,div(NV,NBUSH))
        a0 = zero(rn)
        a3 = zero(rn)
        dk = zero(rn)
        bk = zero(rn)
        be = zero(rn)
        w = zero(v)
        rad2 = zero(rn)
        xrn = zeros(Float64,3,div(NV,NBUSH))
        d2 = zero(rn)
        id = zeros(Int64,div(NV,NBUSH))

        #println("u ",u[1][1,2,2,2,2,2],"\t",u[2][3,1,2,2,4,4],"\t",u[2][3,1,0,0,4,4])
        #exit()

        for ibush = 0:NBUSH -1
            for mu=1:4
                #println("u d " ,u[mu][1,2,2,2,2,2],"\t",u[mu][3,1,2,2,4,4],"\t",u[mu][3,1,0,0,4,4])
                #staple = make_staple(params,u,ibush,mu)
                
                make_staple_double!(staple,u,mu,temp1,temp2,temp3)

                substitute!(temp1,u[mu])
                #Field_g.subst!(ibush,temp1,u[mu])
                mul!(temp2,temp1,staple')

                #display(temp2)
                #exit()

                for k=1:3
                    submat!(temp2,v,div(NV,NBUSH),k,id)
                    for i=1:div(NV,NBUSH)
                        dk[i] =sqrt(v[1,i]^2+v[2,i]^2+v[3,i]^2+v[4,i]^2)
                        bk[i] = 2*beta*dk[i]/3
                        be[i] = 1 -exp(-bk[i])
                        dk[i] = 1/dk[i]
                        id[i] = 0

                        
                    end
                    

                    #=
                    c=============================================
                    c     Kennedy-Pendelton
                    c=============================================
                    =#

                    for ihit=1:nhit
                        rndprd2!(ranf,xrn,div(NV,NBUSH))

                        for i=1:div(NV,NBUSH)
                            if id[i] == 1
                                continue
                            end
                            x1 = xrn[1,i] + eps
                            x2 = xrn[2,i] + eps

                            if x1 <= 0 || x2 <= 0
                                println("x1, x2 : $x1 $x2")
                                println("xrn[1,i],xrn[2,i]:  $(xrn[1,i]) $(xrn[2,i])")
                            end

                            d2[i] = -(log(x1) + log(x2)*cos(2pi*xrn[3,i])^2)/bk[i]
                        end

                        rndprd!(ranf,rn,div(NV,NBUSH))
                        for i=1:div(NV,NBUSH)
                            if id[i] == 1
                                continue
                            end
                            if rn[i]^2 >= 1-0.5*d2[i]
                                continue
                            end
                            id[i] = 1
                            a0[i] = 1-d2[i]
                        end

                        #

                    end

                    #exit()

                    rndprd!(ranf,rn,div(NV,NBUSH))
                    for i=1:div(NV,NBUSH)
                        if id[i] == 0
                            continue
                        end
                        rad = 1-a0[i]^2
                        a3[i] = sqrt(rad)*(2*rn[i]-1)
                        rad2[i] = sqrt(abs(rad-a3[i]^2))
                        #println(rad)
                    end
                    #display(rn)
                    #exit()

                    rndprd!(ranf,rn,div(NV,NBUSH))
                    for i=1:div(NV,NBUSH)
                        if id[i] == 0
                            continue
                        end
                        theta = 2pi*rn[i]
                        a1=rad2[i]*cos(theta)
                        a2=rad2[i]*sin(theta)
                        w[1,i]=dk[i]*( a0[i]*v[1,i]+a1*v[2,i]+a2*v[3,i]+a3[i]*v[4,i])
                        w[2,i]=dk[i]*(-a0[i]*v[2,i]+a1*v[1,i]+a2*v[4,i]-a3[i]*v[3,i])
                        w[3,i]=dk[i]*(-a0[i]*v[3,i]-a1*v[4,i]+a2*v[1,i]+a3[i]*v[2,i])
                        w[4,i]=dk[i]*(-a0[i]*v[4,i]+a1*v[3,i]-a2*v[2,i]+a3[i]*v[1,i])
                    end
                    #display(v)
                    #exit()

                    submat!(temp3,w,div(NV,NBUSH),k+3,id)
                    #display(temp3)
                    #exit()
                    if k <= 2
                        mul!(temp2,temp3,temp1)
                        substitute!(temp1,temp2)
                        #Field_g.subst!(temp1,temp2)
                        mul!(temp2,temp1,staple')
                    elseif k==3
                        mul!(temp2,temp3,temp1)
                        #display(temp2)
                        #exit()
                        substitute!(u[mu],temp2)
                        #Field_g.subst!(ibush,u[mu],temp2)
                    end
                    #display(temp2)
                    #exit()
                    


                end
                #println("u ",u[mu][1,2,2,2,2,2],"\t",u[mu][3,1,2,2,4,4],"\t",u[mu][3,1,0,0,4,4])
                #exit()

                set_wing!(u[mu])
            end
            #exit()
            #println("u ",u[1][1,2,2,2,2,2],"\t",u[2][3,1,2,2,4,4],"\t",u[2][3,1,0,0,4,4])
        end

        #println("u ",u[1][1,2,2,2,2,2],"\t",u[2][3,1,2,2,4,4],"\t",u[2][3,1,0,0,4,4])
        #exit()
    end
    =#

    

    """
-------------------------------------------------c
     su2-submatrix(c) in su3 matrix(x)
            su2            su3
     k=1         <-    1-2 elements
     k=2         <-    2-3 elements
     k=3         <-    1-3 elements
     k=4          ->   1-2 elements
     k=5          ->   2-3 elements
     k=6          ->   1-3 elements
-------------------------------------------------c
    """
    function submat!(x,c,n,k,id)

        if k==1
            for i=1:n
                c[1,i] = real(x[1,1,i]+x[2,2,i])*0.5
                c[2,i] = imag(x[1,2,i]+x[2,1,i])*0.5
                c[3,i] = real(x[1,2,i]-x[2,1,i])*0.5
                c[4,i] = imag(x[1,1,i]-x[2,2,i])*0.5
            end
        elseif k==2
            for i=1:n
                c[1,i] = real(x[2,2,i]+x[3,3,i])*0.5
                c[2,i] = imag(x[3,2,i]+x[2,3,i])*0.5
                c[3,i] = real(x[3,2,i]-x[2,3,i])*0.5
                c[4,i] = imag(x[2,2,i]-x[3,3,i])*0.5
            end

        elseif k==3
            for i=1:n
                c[1,i] = real(x[1,1,i]+x[3,3,i])*0.5
                c[2,i] = imag(x[3,1,i]+x[1,3,i])*0.5
                c[3,i] = real(x[1,3,i]-x[3,1,i])*0.5
                c[4,i] = imag(x[1,1,i]-x[3,3,i])*0.5
            end
        elseif k==4

            for i=1:n
                #println("i = $i")
                #println(c[:,i])
                if id[i] == 1
                    x[1,1,i] = c[1,i] + im*c[4,i]
                    x[1,2,i] = c[3,i] + im*c[2,i]
                    x[1,3,i] = 0
                    x[2,1,i] = -c[3,i] + im*c[2,i]
                    x[2,2,i] = c[1,i] - im*c[4,i]
                    x[2,3,i] = 0
                    x[3,1,i] = 0
                    x[3,2,i] = 0
                    x[3,3,i] = 1

                elseif id[i] == 0
                    x[1,1,i] = 1
                    x[1,2,i] = 0
                    x[1,3,i] = 0
                    x[2,1,i] = 0
                    x[2,2,i] = 1
                    x[2,3,i] = 0
                    x[3,1,i] = 0
                    x[3,2,i] = 0
                    x[3,3,i] = 1
                end 
            end
        elseif k==5
            for i=1:n
                if id[i] == 1
                    x[1,1,i] = 1
                    x[1,2,i] = 0
                    x[1,3,i] = 0
                    x[2,1,i] = 0
                    x[2,2,i] = c[1,i] + im*c[4,i]
                    x[2,3,i] = -c[3,i] + im*c[2,i]
                    x[3,1,i] = 0
                    x[3,2,i] = c[3,i] + im*c[2,i]
                    x[3,3,i] = c[1,i] -im*c[4,i]

                elseif id[i] == 0
                    x[1,1,i] = 1
                    x[1,2,i] = 0
                    x[1,3,i] = 0
                    x[2,1,i] = 0
                    x[2,2,i] = 1
                    x[2,3,i] = 0
                    x[3,1,i] = 0
                    x[3,2,i] = 0
                    x[3,3,i] = 1
                end 
            end

        elseif k==6
            for i=1:n
                if id[i] == 1
                    x[1,1,i] = c[1,i] + im*c[4,i]
                    x[1,2,i] = 0
                    x[1,3,i] = c[3,i] + im*c[2,i]
                    x[2,1,i] = 0
                    x[2,2,i] = 1
                    x[2,3,i] = 0
                    x[3,1,i] = -c[3,i] + im*c[2,i]
                    x[3,2,i] = 0
                    x[3,3,i] = c[1,i] -im*c[4,i]

                elseif id[i] == 0
                    x[1,1,i] = 1
                    x[1,2,i] = 0
                    x[1,3,i] = 0
                    x[2,1,i] = 0
                    x[2,2,i] = 1
                    x[2,3,i] = 0
                    x[3,1,i] = 0
                    x[3,2,i] = 0
                    x[3,3,i] = 1
                end 
            end
        end
    end

    function rndprd!(ranf,n)
        rn = zeros(Float64,n)
        rndprd!(ranf,rn,n)
        return rn
    end

    function rndprd!(ranf,rn,n)
        for i=1:n
            rn[i] = ranf()
        end
        return rn
    end

    function rndprd2!(ranf,n)
        xrn = zeros(Float64,3,n)
        rndprd2!(ranf,xrn,n)
        return xrn
    end

    function rndprd2!(ranf,xrn,n)
        for j=1:n
            for i=1:3
                xrn[i,j] = ranf()
            end
        end
        return 
    end


end