module TestAqua

using Aqua
using Try
using TryExperimental

test_try() = Aqua.test_all(Try)
test_tryexperimental() = Aqua.test_all(TryExperimental)

end  # module
