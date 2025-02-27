//
//  VideoRepositoryProtocol.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/6/25.
//


protocol VideoRepositoryProtocol {
    func fetchAllVideos() -> [Videos]
    func fetchVideos(showOnHome: Bool) -> [Videos]
    func addVideo(activationPhrase: String?, keyword: String?, showOnHome: Bool, videoURL: String?)
    func deleteVideo(_ video: Videos)
    func fetchVideo(matching text: String) -> Videos?
    func updateVideo(activationPhrase: String?, keyword: String?, showOnHome: Bool, videoURL: String? , videoObj : Videos)
}
