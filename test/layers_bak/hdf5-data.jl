println("-- Testing HDF5DataLayer...")

using HDF5

############################################################
# Prepare Data for Testing
############################################################
batch_size = 3
data_dim = (2,)#(2,3,4)
eps = 1e-15

data_all = [rand(x, data_dim...) for x in [5 1 2]]
h5fn_all = [string(tempname(), ".hdf5") for x in 1:length(data_all)]

for i = 1:length(data_all)
  h5 = h5open(h5fn_all[i], "w")
  h5["data"] = data_all[i]
  close(h5)
end

source_fn = string(tempname(), ".txt")
open(source_fn, "w") do s
  for fn in h5fn_all
    println(s, fn)
  end
end

############################################################
# Setup
############################################################
sys = System(CPU())

# batch size is determined by 
layer = HDF5DataLayer(; source = source_fn, tops = String["data"], batch_size=batch_size)
state = setup(sys, layer, Blob[])

data = cat(1, data_all...)
data = cat(1, data, data)

data_idx = map(x->1:x, data_dim)
for i = 1:batch_size:size(data,1)-batch_size
  forward(sys, state, Blob[])
  @test all(-eps .< state.blobs[1].data - data[i:i+batch_size-1, data_idx...] .< eps)
end
