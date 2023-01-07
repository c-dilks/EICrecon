#!/usr/bin/env ruby

# procedure:
# - generate a simulation file with 1 event, to ../out/sim.root
# - run
#     diff.rb | tee diff.txt
# - remove unimportant differences from diff.txt

skipEICrecon = ARGV.length>0
SimFile =  '../out/sim.root'

cmdRec = [
  # 'echo',
  'run_eicrecon_reco_flags.py',
  SimFile,
  'rec_test',
]
cmdCpp = [
  # 'echo',
  'eicrecon',
  '-Pplugins=dump_flags',
  '-Pdump_flags:python=all_flags_dump_from_run.py',
  '-Pjana:debug_plugin_loading=1',
  '-Pjana:nevents=0',
  '-Pacts:MaterialMap=calibrations/materials-map.cbor',
  '-Ppodio:output_file=rec_test.tree.edm4eic.root',
  '-Phistsfile=rec_test.ana.root',
  SimFile,
]

fRec = "flags_rec"
fCpp = "flags_cpp"

unless skipEICrecon
  def run_eicrecon(cmd,output)
    system cmd.join(' ') + " | grep '^   .* : .*' > #{output}"
  end
  run_eicrecon cmdRec, fRec
  run_eicrecon cmdCpp, fCpp
end

def makeHash(file)
  File.readlines(file).map do |line|
    name, val = line.split(' : ').map do |s|
      s.gsub(/ /, '').chomp
    end
    [name, val]
  end.to_h
end

hRec = makeHash(fRec)
hCpp = makeHash(fCpp)

hRec.each do |k,vRec|
  if hCpp.has_key? k
    vCpp = hCpp[k]
    if vRec != vCpp
      puts "#{k} => #{vRec} VS #{vCpp}"
    end
  # else
  #   puts "#{k} => not found in fCpp"
  end
end
