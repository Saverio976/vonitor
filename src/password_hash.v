import crypto.blake2s

pub fn hash_password(password string, salt string) !string {
	mut digest := blake2s.new256() or { return error("Can't create a digest") }
	digest.write('${salt}${password}'.bytes()) or { return error("Can't write to digest") }
	return digest.checksum().hex()
}
