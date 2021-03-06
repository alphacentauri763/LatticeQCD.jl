module Wizard
    using REPL.TerminalMenus
    import ..System_parameters:Params_set,print_parameters,Params

    function print_wizard_logo(outs)
        blue    = "\033[34m"
        red     = "\033[31m"
        green   = "\033[32m"
        magenta = "\033[35m"
        normal  = "\033[0m\033[0m"

        logo = raw"""
    --------------------------------------------------------------------------------  
    run_wizard       
    　　　　　格　　　　　　　格　　　　　　　
    　　　　　色　　　　　　　格　　　　
    　　　　色色色　　　　　　格　　　
    　子子色色色色色子子子子子格子子子子
    　　　　色色色　　　　　　格　　　　
    　　　　　色　　　　　　　格　　　
    　　　　　格　　　　　　　格　　　
    　　　　　力　　　　　　　学　　　　　　LatticeQCD.jl
    　　　　力力力　　　　　学学学　　　
    　子子力力力力力子子子学学学学学子子　　
    　　　　力力力　　　　　学学学　　　　　
    　　　　　力　　　　　　　学　　　　　　
    　　　　　格　　　　　　　格　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　
        """


        logo = replace(logo, "Q" => "$(red)Q$(normal)")
        logo = replace(logo, "C" => "$(blue)C$(normal)")
        logo = replace(logo, "D" => "$(green)D$(normal)")
        logo = replace(logo, "色" => "$(red)色$(normal)")
        logo = replace(logo, "力" => "$(blue)力$(normal)")
        logo = replace(logo, "学" => "$(green)学$(normal)")

        println(outs, logo)
        println(outs,
            "Welcome to a wizard for Lattice QCD.\n",
            "We'll get you set up simulation parameters in no time."
        )
        println("--------------------------------------------------------------------------------")
        println("If you leave the prompt empty, a default value will be used.")
        println("To exit, press Ctrl + c.")
    end

    function wilson_wizard_simple!(system)
        wilson = Dict()
        cg = Dict()
        staggered = Dict()
        wtype = 1

        if wtype == 1
            println("Standard Wilson fermion action will be used")
            system["Dirac_operator"] = "Wilson"
        else
            println("Wilson+Clover fermion action will be used")
            system["Dirac_operator"] = "WilsonClover"
        end

        #println("Inut the hopping parameter κ: typical value = 0.141139")
        hop = parse(Float64,Base.prompt("Input the hopping parameter κ", default="0.141139"))
        #hop = parse(Float64,readline(stdin))
        if hop <= 0
            error("Invalid value for κ=$hop. This has to be strictly positive.")
        end
        wilson["hop"] = hop
        println("κ = $hop")
        wilson["r"] = 1
        wilson["Clover_coefficient"] = 1.5612

        eps = 1e-19
        MaxCGstep = 3000

        cg["eps"] = eps
        cg["MaxCGstep"] =MaxCGstep 
        return wilson,cg,staggered,system
    end

    function wilson_wizard!(system)
        wilson = Dict()
        cg = Dict()
        staggered = Dict()
        wtype = request("Choose Wilson fermion type",RadioMenu([
                    "Standard Wilson fermion action",
                    "Wilson+Clover fermion action",
                ]))
        if wtype == 1
            println("Standard Wilson fermion action will be used")
            system["Dirac_operator"] = "Wilson"
        else
            println("Wilson+Clover fermion action will be used")
            system["Dirac_operator"] = "WilsonClover"
        end

        #println("Inut the hopping parameter κ: typical value = 0.141139")
        hop = parse(Float64,Base.prompt("Input the hopping parameter κ", default="0.141139"))
        #hop = parse(Float64,readline(stdin))
        if hop <= 0
            error("Invalid value for κ=$hop. This has to be strictly positive.")
        end
        wilson["hop"] = hop
        println("κ = $hop")
        wilson["r"] = 1
        wilson["Clover_coefficient"] = 1.5612

        eps = parse(Float64,Base.prompt("relative error in CG loops", default="1e-19"))
        MaxCGstep = parse(Int64,Base.prompt("Maximum iteration steps in CG loops", default="3000"))
        if eps<=0
            error("Invalid value for eps=$eps. This has to be strictly positive.")
        end
        if MaxCGstep<=0
            error("Invalid value for MaxCGstep=$MaxCGstep. This has to be strictly positive.")
        end
        cg["eps"] = eps
        cg["MaxCGstep"] =MaxCGstep 
        return wilson,cg,staggered,system
    end

    function staggered_wizard!(system)
        wilson = Dict()
        cg = Dict()
        staggered = Dict()
        system["Dirac_operator"] = "Staggered"

        mass = parse(Float64,Base.prompt("Input mass", default="0.5"))
        if mass<=0
            error("Invalid value for mass=$mass. This has to be strictly positive.")
        end
        staggered["mass"] = mass
        staggered["Nf"] = 4

        eps = parse(Float64,Base.prompt("relative error in CG loops", default="1e-19"))
        MaxCGstep = parse(Int64,Base.prompt("Maximum iteration steps in CG loops", default="3000"))
        if eps<=0
            error("Invalid value for eps=$eps. This has to be strictly positive.")
        end
        if MaxCGstep<=0
            error("Invalid value for MaxCGstep=$MaxCGstep. This has to be strictly positive.")
        end
        cg["eps"] = eps
        cg["MaxCGstep"] = MaxCGstep 
        return wilson,cg,staggered,system
    end

    function run_wizard()        
        print_wizard_logo(stdout)
        simple = request("Choose wizard mode",RadioMenu([
            "simple",
            "expert",
        ]))
        if simple == 1
            isexpert = false
            #return run_wizard_simple()
        else
            isexpert = true
        end

    

        system = Dict()
        md = Dict()
        actions = Dict()
        actions["use_autogeneratedstaples"] = false
        actions["couplinglist"] = []
        actions["couplingcoeff"] = []

        filename = Base.prompt("put the name of the parameter file you make", default="parameters_used.jl")

        if isexpert 
            verboselevel = parse(Int64,Base.prompt("verbose level ?", default="2"))
        else
            verboselevel = 1
        end

        if 1 ≤ verboselevel ≤ 3
            println("verbose level = ",verboselevel)
        else
            error("verbose level should be 1 ≤ verboselevel ≤ 3")
        end
        
        system["verboselevel"] = verboselevel

        if isexpert 
            system["randomseed"] = parse(Int64,Base.prompt("Input random seed.", default="111"))
        else
            system["randomseed"] = 111
        end

        if isexpert 
            println("Input Lattice size, L=(Nx,Ny,Nz,Nt)")
            NX = parse(Int64,Base.prompt("Nx ?", default="4"))
            NY = parse(Int64,Base.prompt("Ny ?", default="4"))
            NZ = parse(Int64,Base.prompt("Nz ?", default="4"))
            NT = parse(Int64,Base.prompt("Nt ?", default="4"))
            #NT = parse(Int64,readline(stdin))
            L = (NX,NY,NZ,NT)
            system["L"] = L
            if (NX<= 0)|(NY<= 0)|(NZ<= 0)|(NT<= 0)
                error("Invalid parameter L=$L, elements must be positive integers")
            end
        else
            NX = parse(Int64,Base.prompt("Input spatial lattice size ", default="4"))
            NT = parse(Int64,Base.prompt("Input temporal lattice size ", default="4"))
            L = (NX,NX,NX,NT)
            system["L"] = L
            if (NX<= 0)|(NT<= 0)
                error("Invalid parameter L=$L, elements must be positive integers")
            end
        end

        println("Lattice is $L")

        if isexpert 
            SNC = request("Choose a gauge group",RadioMenu([
                        "SU(2)",
                        "SU(3)",
                    ]))
            NC = ifelse(SNC == 1,2,3)
        else
            NC = 3
        end

        system["NC"] = NC
        println("SU($NC) will be used")

        if NC == 3
            β = parse(Float64,Base.prompt("β ?", default="5.7"))
        elseif NC == 2
            β = parse(Float64,Base.prompt("β ?", default="2.7"))
        end
        system["β"] = β
        if β<0
            error("Invalid value for β=$β. This has to be positive or zero")
        end

        if NC == 3
            initialconf = request("Choose initial configurations",RadioMenu([
                        "cold start",
                        "hot start",
                        "start from a file",
                    ]))
        elseif NC == 2
            initialconf = request("Choose initial configurations",RadioMenu([
                    "cold start",
                    "hot start",
                    "start from a file",
                    "start from one instanton (Radius is half of Nx)",
                ]))
        end
        if initialconf == 1
            system["initial"] = "cold"
        elseif initialconf == 2
            system["initial"] = "hot"
        elseif initialconf == 3
            system["initial"] = Base.prompt("Input the file name that you want to use",default="./confs/conf_00000001.jld")
        elseif initialconf == 4
            system["initial"] = "Start from one instanton"
        end
        #system["initial"] = ifelse(initialconf == 1,"cold","hot")

        system["BoundaryCondition"] = [1,1,1,-1]
        system["Nwing"] = 1



        if isexpert 

            ftype = request("Choose a dynamical fermion",RadioMenu([
                        "Nothing (quenched approximation)",
                        "Wilson Fermion (2-flavor)",
                        "Staggered Fermion (4-tastes)",
                    ]))
            if ftype == 1
                cg = Dict()
                wilson = Dict()
                staggered = Dict()
                system["Dirac_operator"] = nothing
                system["quench"] = true

                
            elseif ftype == 2
                wilson,cg,staggered,system = wilson_wizard!(system)
                system["quench"] = false
            elseif ftype == 3
                wilson,cg,staggered,system = staggered_wizard!(system)
                system["quench"] = false
            end

            if system["quench"] == true
                methodtype = request("Choose an update method",RadioMenu([
                    "Hybrid Monte Carlo",
                    "Heatbath",
                ]))
                if methodtype == 1
                    system["update_method"] = "HMC"
                else
                    system["update_method"] = "Heatbath"
                end
            else
                methodtype = request("Choose an update method",RadioMenu([
                    "Hybrid Monte Carlo",
                    "Integrated HMC",
                    "Self-learning Hybrid Monte Carlo (SLHMC)",
                ]))
                if methodtype == 1
                    system["update_method"] = "HMC"
                elseif methodtype == 2
                    system["update_method"] = "IntegratedHMC"
                else
                    system["update_method"] = "SLHMC"
                    system["βeff"] = parse(Float64,Base.prompt("Input initial effective β", default="$β"))
                    system["firstlearn"] = parse(Int64,Base.prompt("When do you want to start updating the effective action?", default="10"))
                    system["quench"] = true
                end
            end

            savetype = request("Choose a configuration format for saving",RadioMenu([
                    "no save",
                    "JLD",
                ]))
            if savetype == 2
                system["saveU_format"] = "JLD"
                
            elseif savetype == 1
                system["saveU_format"] = nothing
                system["saveU_dir"] = ""
            end

            if system["saveU_format"] ≠ nothing
                system["saveU_every"] = parse(Int64,Base.prompt("Timing for saving configuration", default="1"))
                system["saveU_dir"] = Base.prompt("Saving directory", default="./confs")
            end

            if system["update_method"] == "HMC" || system["update_method"] == "IntegratedHMC" || system["update_method"] == "SLHMC"|| system["update_method"] == "Heatbath"
                Nthermalization = parse(Int64,Base.prompt("Input number of thermalization steps", default="10"))
                Nsteps = parse(Int64,Base.prompt("Input number of total trajectories", default="100"))

                if Nthermalization<0
                    error("Invalid value for Nthermalization=$Nthermalization. This has to be positive/zero.")
                end
                if Nsteps<=0
                    error("Invalid value for Nsteps=$Nsteps. This has to be strictly positive.")
                end
                system["Nthermalization"] = Nthermalization
                system["Nsteps"] = Nsteps
            end

            if system["update_method"] == "HMC" || system["update_method"] == "IntegratedHMC" || system["update_method"] == "SLHMC"
                println("Choose parameters for MD")
                MDsteps = parse(Int64,Base.prompt("Input MD steps", default="20"))
                Δτ = parse(Float64,Base.prompt("Input Δτ", default="$(1/MDsteps)"))
                
                #SextonWeingargten = parse(Bool,Base.prompt("Use SextonWeingargten method? true or false", default="false"))

                SW = request("Use SextonWeingargten method? multi-time scale",RadioMenu([
                        "false",
                        "true",
                    ]))
                SextonWeingargten = ifelse(SW==1,false,true)
                
                if SextonWeingargten
                    N_SextonWeingargten = parse(Int64,Base.prompt("Input number of SextonWeingargten steps", default="2"))
                else
                    N_SextonWeingargten = 2
                end

                if MDsteps<=0
                    error("Invalid value for MDsteps=$MDsteps. This has to be strictly positive.")
                end
                if Δτ<=0
                    error("Invalid value for Δτ=$Δτ. This has to be strictly positive.")
                end

                md["MDsteps"] = MDsteps
                md["Δτ"] = Δτ
                md["SextonWeingargten"] = SextonWeingargten
                md["N_SextonWeingargten"] = N_SextonWeingargten
            end
        else
            system["Dirac_operator"] = "Wilson"

            wilson,cg,staggered,system = wilson_wizard_simple!(system)
            system["quench"] = false

            system["update_method"] = "HMC"


            system["saveU_format"] = nothing
            system["saveU_dir"] = ""

            MDsteps = 20
            Δτ = 1/MDsteps

            SextonWeingargten = false
            N_SextonWeingargten = 2


            Nthermalization = 0
            Nsteps = parse(Int64,Base.prompt("Input number of total trajectories", default="100"))

            if Nsteps<=0
                error("Invalid value for Nsteps=$Nsteps. This has to be strictly positive.")
            end

            md["MDsteps"] = MDsteps
            md["Δτ"] = Δτ
            md["SextonWeingargten"] = SextonWeingargten
            md["N_SextonWeingargten"] = N_SextonWeingargten
            system["Nthermalization"] = Nthermalization
            system["Nsteps"] = Nsteps
        end

        measurement = Dict()

        options = ["Plaquette","Polyakov_loop","Topological_charge","Chiral_condensate","Pion_correlator"]

        if isexpert 
            measurementmenu = MultiSelectMenu(options)
            choices = request("Select the measurement methods you want to do:", measurementmenu)
            nummeasurements  = length(choices)
            #println(choices)
            measurement_methods = Array{Dict,1}(undef,nummeasurements)
            count = 0
            
            for  i in choices
                count += 1
                if i == 1
                    measurement_methods[count] = plaq_wizard()
                elseif i == 2
                    measurement_methods[count] = poly_wizard()
                elseif i == 3
                    measurement_methods[count] = topo_wizard()
                elseif i == 4
                    measurement_methods[count] = chiral_wizard(staggered)
                elseif i == 5
                    measurement_methods[count] = pion_wizard(wilson)
                end
            end
        else
            choices =  [1,2,5]
            nummeasurements  = length(choices)
            #println(choices)
            measurement_methods = Array{Dict,1}(undef,nummeasurements)
            count = 0
            
            for  i in choices
                count += 1
                if i == 1
                    measurement_methods[count] =Dict()
                    println("You measure plaquette")
                    measurement_methods[count]["methodname"] = "Plaquette"
                    measurement_methods[count]["measure_every"] = 1#parse(Int64,Base.prompt("How often measure Plaquette loops?", default="1"))
                    measurement_methods[count]["fermiontype"] = nothing

                elseif i == 2
                    measurement_methods[count] =Dict()
                    println("You measure Polyakov loop")
                    measurement_methods[count]["methodname"] = "Polyakov_loop"
                    measurement_methods[count]["measure_every"] = 1#parse(Int64,Base.prompt("How often measure Plaquette loops?", default="1"))
                    measurement_methods[count]["fermiontype"] = nothing
                elseif i == 5
                    measurement_methods[count] =Dict()
                    measurement_methods[count] = pion_wizard_simple(wilson)
                end
            end
        end

        #measurement["measurement_methods"] = nothing
        #if nummeasurements ≠ 0
        measurement["measurement_methods"] = measurement_methods
        #end

        params_set = Params_set(system,actions,md,cg,wilson,staggered,measurement)

        
        print_parameters(filename,params_set)

        #p = Params(params_set)

        println("""
        --------------------------------------------------------------------------------  
        run_wizard is done. 
        
        The returned value in this run_wizard() is params_set.
        If you want to run a simulation in REPL or other Julia codes,  just do

        run_LQCD(params_set)

        or 

        run_LQCD("$filename")

        The output parameter file is $filename. 
        If you want to run a simulation, just do

        julia run.jl $filename

        --------------------------------------------------------------------------------  
        """)
        
        return params_set
    end

    function  plaq_wizard()
        method = Dict()

        println("You measure Plaquette loops")
        method["methodname"] = "Plaquette"
        method["measure_every"] = parse(Int64,Base.prompt("How often measure Plaquette loops?", default="1"))
        method["fermiontype"] = nothing

        return method
    end

    function  poly_wizard()
        method = Dict()

        println("You measure Polyakov loops")
        method["methodname"] = "Polyakov_loop"
        method["measure_every"] = parse(Int64,Base.prompt("How often measure Polyakov loops?", default="1"))
        method["fermiontype"] = nothing

        return method
    end

    function  topo_wizard()
        method = Dict()
        println("You measure a topological charge")
        method["methodname"] = "Topological_charge"
        method["measure_every"] = parse(Int64,Base.prompt("How often measure a topological charge?", default="10"))
        method["fermiontype"] = nothing
        method["numflow"]  = parse(Int64,Base.prompt("How many times do you want to flow gauge fields to measure the topological charge?", default="10"))

        return method
    end

    function  chiral_wizard(staggered)
        if haskey(staggered,"mass")
            mass_default = staggered["mass"]
        else
            mass_default = 0.5
        end


        method = Dict()
        println("You measure chiral condensates with the statteggred fermion")

        method["methodname"] = "Chiral_condensate" 
        method["measure_every"] = parse(Int64,Base.prompt("How often measure chiral condensates?", default="10"))
        method["fermiontype"] = "Staggered"
        method["mass"] = parse(Float64,Base.prompt("Input mass for the measurement of chiral condensates", default="$mass_default"))
        method["Nf"] = 4
    

        return method
    end
    function  pion_wizard(wilson)
        if haskey(wilson,"hop")
            hop_default = wilson["hop"]
        else
            hop_default = 0.141139
        end

        method = Dict()

        println("You measure Pion_correlator with the Wilson quark operator")

        method["methodname"] = "Pion_correlator" 
        method["measure_every"] = parse(Int64,Base.prompt("How often measure Pion_correlator?", default="10"))
        wtype = request("Choose Wilson fermion type for the measurement of Pion_correlator",RadioMenu([
                    "Standard Wilson fermion action",
                    "Wilson+Clover fermion action",
                ]))
        if wtype == 1
            println("Standard Wilson fermion action will be used for the measurement")
            method["fermiontype"] = "Wilson"
        else
            println("Wilson+Clover fermion action will be used for the measurement")
            method["fermiontype"] = "WilsonClover"
        end

        hop = parse(Float64,Base.prompt("Input the hopping parameter κ for the measurement", default="$hop_default"))
        if hop <= 0
            error("Invalid parameter κ=$hop")
        end
        method["hop"] = hop
        method["r"] = 1

        return method
    end

    function  pion_wizard_simple(wilson)
        if haskey(wilson,"hop")
            hop_default = wilson["hop"]
        else
            hop_default = 0.141139
        end

        method = Dict()

        println("You measure Pion_correlator with the Wilson quark operator")

        method["methodname"] = "Pion_correlator" 
        method["measure_every"] = 10
        println("Standard Wilson fermion action will be used for the measurement")
        method["fermiontype"] = "Wilson"

        hop = hop_default
        if hop <= 0
            error("Invalid parameter κ=$hop")
        end
        method["hop"] = hop
        method["r"] = 1

        return method
    end


end

#using .Wizard
#Wizard.run_wizard()