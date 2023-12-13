# ExchangeUnitful
This package enables conversion of [Unitful](https://github.com/PainterQubits/Unitful.jl) types into [UnitTypes](https://github.com/mechanomy/UnitTypes.jl) for units whose unit symbols are identical.
See UnitTypes for more information.

```julia
using Unitful
using UnitTypes, ExchangeUnitful

@show 1u"m" + Meter(3)

#convert into UnitTypes
@show convert(Meter, 1.2u"m")
@show convert(Meter, 1.2u"mm")

#convert into Unitful
@show convert(typeof(1u"m"), Millimeter(1.2))
@show convert(typeof(1u"m"), Meter(1.2))
```

<!-- [![Build Status](https://github.com/mechanomy/ExchangeUnitful.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mechanomy/ExchangeUnitful.jl/actions/workflows/CI.yml?query=branch%3Amain) -->

## Copyright
Copyright (c) 2023 - Mechanomy LLC

## License
Released under [MIT](./license.md).

