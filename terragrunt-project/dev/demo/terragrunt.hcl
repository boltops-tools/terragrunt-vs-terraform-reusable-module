terraform {
  source = "git::https://github.com/tongueroo/pet.git//"
}

include {
  path = find_in_parent_folders()
}
