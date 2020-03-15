/*
 * Created by Ilan Rasekh on 2020/3/13
 * Copyright (c) 2020 Pseudorand Development. All rights reserved.
 */

// TODO: replace with better terminology
enum VaultSource { Internal, External }

class Vault {
  String id;
  String nickname;
  VaultSource source;

  Vault(this.id, this.nickname, this.source);
}
