# MIT License
# Copyright (c) 2023 Mechanomy LLC
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""
  This package enables conversion of Unitful types into UnitTypes for units whose unit symbols are identical.

  ```julia
  using Unitful
  using UnitTypes, ExchangeUnitful

  @show 1u"m" + Meter(3)
  ```
"""
# TestItemRunner doesn't like docstrings... https://github.com/julia-vscode/TestItemRunner.jl/issues/33 
module ExchangeUnitful
  # ExchangeUnitful provides converts() between Unitful and UnitTypes, allowing Unitful quantities to be given to UnitType-d functions
  using TestItemRunner
  using UnitTypes
  using InteractiveUtils #subtypes
  import Unitful

  # The mapping relies on types have equivalent unit signs in Unitful.uparse(UnitTypes.[type].unit)
  Base.convert(::Type{T}, x::U) where {T<:Unitful.AbstractQuantity, U<:AbstractMeasure} = x.value * Unitful.uparse(x.unit) # Unitful.AbstractQuantity is for typeof(1u"m")
  Base.convert(::Type{T}, x::U) where {T<:AbstractMeasure, U<:Unitful.AbstractQuantity} = T(Unitful.ustrip(Unitful.uparse(T(1.0).unit), x))

  # convert to UnitTypes:
  Base.:+(x::T, y::U) where {T<:AbstractMeasure, U<:Unitful.AbstractQuantity} = x + convert(T, y) 
  Base.:+(x::T, y::U) where {T<:Unitful.AbstractQuantity, U<:AbstractMeasure} = convert(U,x) + y
  Base.:-(x::T, y::U) where {T<:AbstractMeasure, U<:Unitful.AbstractQuantity} = x - convert(T, y) 
  Base.:-(x::T, y::U) where {T<:Unitful.AbstractQuantity, U<:AbstractMeasure} = convert(U,x) - y
  # omit */ to avoid the confusion of Meter(3)*1u"m" = Meter2;

  # # add constructors to all types defined in UnitTypes
  # utNames = names(UnitTypes, all=false, imported=false)
  # filter!(n->Base.isconcretetype(eval(Symbol(string(n)))), utNames) #filter abstract types
  # # utn = utNames[10]
  # for utn in utNames
  #   unit = eval(utn)(1.2).unit
  #   eval(:( $utn(x::T where T<:Unitful.AbstractQuantity) = $utn(Unitful.ustrip(Unitful.uparse($unit) , x)))  ) # rely on uparse to convert into 'base'
  # end

  """
    `addConstructorsForAllUnitTypes()`

    Adds constructors for all types <:AbstractMeasure, those in UnitTypes and user-defined.
    This may need to be re-run for programmaticaly-defined types.
  """
  function addConstructorsForAllUnitTypes()
    for aType in subtypes(AbstractMeasure)
      for utn in subtypes(aType) # Foot <: AbstractLength <: AbstractMeasure
        unit = utn(1.2).unit
        :( $utn(x::T where T<:Unitful.AbstractQuantity) = $utn(Unitful.ustrip(Unitful.uparse($unit) , x))) # rely on uparse to convert into 'base'
      end
    end
  end
  addConstructorsForAllUnitTypes() # run on load

  @testitem "ExchangeUnitful" begin
    using UnitTypes
    using Unitful

    #assemble a list of concrete types
    utNames = names(UnitTypes, all=false, imported=false)
    # display(utNames)
    filter!(n->Base.isconcretetype(eval(Symbol(string(n)))), utNames) #filter abstract types
    for ut in utNames
    # for ut in [utNames[10]]
      unitType = eval(ut)# eval needed to convert the symbol into the type
      a = unitType(1.2) 
      try 
        Unitful.uparse(a.unit)
      catch err
        println("Unitful.uparse unable to parse UnitType symbol [$(a.unit)] for measure $(typeof(a)), skipping test.")
      else
        @testset "Convert $ut to Unitful" begin
          b = 1.2 * Unitful.uparse(a.unit)
          c = convert(typeof(b), a)
          @test c ≈ b # compare as Unitful
        end
        @testset "Convert Unitful to $ut" begin
          b = 1.2 * Unitful.uparse(a.unit)
          c = convert(unitType, b) 
          @test c ≈ a # compare as UnitType
        end

        @testset "Construct $ut(Unitful)" begin
          @test !(typeof(a.value) <: Unitful.AbstractQuantity) 
          @test typeof(a.value) <: Number
        end

        # @testset "Construct Unitful($ut)" begin
          # when would I want to construct something via UnitTypes...? a = Unitful.{?}( Meter(3.4) ) instead of a = 3.4u"m"?
        # end

        @testset "mixing operators" begin
          a = unitType(1.2)
          b = 1.2*Unitful.uparse(a.unit)
          @test isa(a+b, unitType)
          @test isa(b+a, unitType)
          @test isa(a-b, unitType)
          @test isa(b-a, unitType)

          @test a+b ≈ unitType(2.4)
          @test b+a ≈ unitType(2.4)
          @test a-b ≈ unitType(0)
          @test b-a ≈ unitType(0)
        end
      end # try/catch/else
    end #for

    # @testset "Working with new units" begin ...can add if needed
    #   # https://painterqubits.github.io/Unitful.jl/stable/newunits/
    #   using UnitTypes
    #   using Unitful
    #   @unit Donughts "Donughts"
    # end
  end #testitem

end