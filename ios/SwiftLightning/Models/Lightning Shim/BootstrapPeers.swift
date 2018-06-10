//
//  BootstrapPeers.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-06-08.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

struct BootstrapPeer {
  
  var nodePubKey: String
  var nodeAddr: String
  var port: Int
  
  static let defaultPort: Int = 9735
  
  static let list = [
    BootstrapPeer(nodePubKey: "02311adba6fa14d7ace86d95b24fbdcaf5d99c0e8a12e49c66a857b7859bb213a5", nodeAddr: "ln-tn-uswest1.swiftlightning.io", port: 9735),
    BootstrapPeer(nodePubKey: "03193d512b010997885b232ecd6b300917e5288de8785d6d9f619a8952728c78e8", nodeAddr: "testnet-lnd.htlc.me", port: defaultPort),
    BootstrapPeer(nodePubKey: "02212d3ec887188b284dbb7b2e6eb40629a6e14fb049673f22d2a0aa05f902090e", nodeAddr: "testnet-lnd.yalls.org", port: defaultPort),
    BootstrapPeer(nodePubKey: "03933884aaf1d6b108397e5efe5c86bcf2d8ca8d2f700eda99db9214fc2712b134", nodeAddr: "endurance.acinq.co", port: 9735),
    BootstrapPeer(nodePubKey: "038863cf8ab91046230f561cd5b386cbff8309fa02e3f0c3ed161a3aeb64a643b9", nodeAddr: "180.181.208.42", port: 9735),  // aranguren.org
    BootstrapPeer(nodePubKey: "02ca22bc12c1c21901c284034d3caad5432f495d440e05a3fc96bfa54e09138d3d", nodeAddr: "87.79.193.141", port: 9735),  // Sir Lightning
    BootstrapPeer(nodePubKey: "03fd0aebde8713e9c311f22468d3d0524e788b1ef57f4cda41bf5b5a2300fc5cd6", nodeAddr: "86.61.67.183", port: 9735),  // ruphware++
    BootstrapPeer(nodePubKey: "03a0df42e93655311fee911f857a5cf1c6415f395f6396bb5ac756cbc6f3532601", nodeAddr: "46.101.224.13", port: 9735),  // DeutscheTestnetBank
    BootstrapPeer(nodePubKey: "02651acf4a7096091bf42baad19b3643ea318d6979f6dcc16ebaec43d5b0f4baf2", nodeAddr: "82.119.233.36", port: 19735),  // Flexo
    BootstrapPeer(nodePubKey: "035b8626ba9fc3f3bd1050767fa4010f3d73a1a6607d14cbf620917692741d7289", nodeAddr: "18.191.57.14", port: 9735),  // lordofdarkness
    BootstrapPeer(nodePubKey: "02e8d54ff99dc2e4c5697626f87a216adb339a9c91c50b9bff21955656dfd2249b", nodeAddr: "78.42.161.43", port: 19735),  // iuno-010389
    BootstrapPeer(nodePubKey: "023ea0a53af875580899da0ab0a21455d9c19160c4ea1b7774c9d4be6810b02d2c", nodeAddr: "btctest.lnetwork.tokyo", port: 9735),
    BootstrapPeer(nodePubKey: "0383790804f507c7cc7e8afca03a6ff05f9281bfdff2aed555cb15b4276a288100", nodeAddr: "35.168.53.43", port: 9735),  // Arcade Lightning ≡ƒæ╛
    BootstrapPeer(nodePubKey: "025737de2aacb7dea16b2c497b406f4fb36dc45c773e7dbd7c9a3d0c99aa3c378b", nodeAddr: "94.155.50.126", port: 29735),  // peernode.net
    BootstrapPeer(nodePubKey: "020a3ce6e6893749bbcdb67ac67570e816a17c678bbcb6b12b0325f3fec036a014", nodeAddr: "189.4.126.1", port: 9735)  // md5hash
  ]
}

