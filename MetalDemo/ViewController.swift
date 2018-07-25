//
//  ViewController.swift
//  MetalDemo
//
//  Created by Ray on 2018/6/27.
//  Copyright © 2018年 Ray. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    private var device: MTLDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        self.label.text = device.name
    }

    private func render() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let rpd = MTLRenderPassDescriptor()
        let bleen = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
//        rpd.colorAttachments[0].texture
    }

}
class  MetalView: MTKView {
    
    private var commandQueue: MTLCommandQueue?
    private var rps: MTLRenderPipelineState?
    private var vertexData: [Float] = []
    private var vertexBuffer: MTLBuffer?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.render()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawRender()
    }
    
    private func render() {
        self.device = MTLCreateSystemDefaultDevice()
        guard let device = self.device else { return }
        commandQueue = device.makeCommandQueue()
        vertexData = [-1.0, -1.0, 0.0, 1.0,
                       1.0, -1.0, 0.0, 1.0,
                       0.0,  1.0, 0.0, 1.0]
        let dataSize = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        guard let library = device.makeDefaultLibrary() else { return }
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        // 顏色
        rpld.fragmentFunction = frag_func
        // 具有BGRA順序的四個8位歸一化無符號整數分量的普通格式。
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            rps = try device.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            print("error:", error)
        }
    }
    
    private func drawRender() {
        guard let commandQueue = commandQueue, let rps = rps else { return }
        guard let drawable = currentDrawable, let rpd = currentRenderPassDescriptor else { return }
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0.7, green: 0.2, blue: 0.5, alpha: 1)
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
        commandEncoder?.setRenderPipelineState(rps)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    // 畫背景顏色
    private func drawBackColor() {
        // GPU. 處理命令隊列中的渲染和計算指令 
        guard let device = self.device else { return }
        // currentDrawable and currentRenderPassDescriptor 在繪畫前不可為 nil
        guard let drawable = currentDrawable, let rpd = currentRenderPassDescriptor else { return }
        /* 紋理
         * colorAttachments 紋理數組
         *
         */
        rpd.colorAttachments[0].texture = drawable.texture
        // 清除原本顏色時所使用的顏色
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0.7, green: 0.2, blue: 0.5, alpha: 1)
        // 渲染開始時 此為渲染命令編碼器執行的操作
        rpd.colorAttachments[0].loadAction = .clear
        let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
        // 使用緩衝器來建立 render command encoder(渲染指令編碼) 執行繪製指令
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
