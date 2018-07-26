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
    
    // 創建並返回串行命令提交隊列
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
                     // x     y  z(深度) w
        vertexData = [-1.0, -1.0, 0.0, 1.0, // 左下
                       1.0, -1.0, 0.0, 1.0, // 右下
                       0.0,  1.0, 0.0, 1.0] // 中上
        
        //
        // 「 齊次座標 」{ 為了方便將空間的平移、縮放、旋轉等轉換使用矩陣來記錄 }
        //
        //  齊次座標使用 (x, y, z, w)來表示 轉換為三維坐標 -> (x/w, y/w, z/w)
        //  w表示座標軸的遠近參數 通常設 1，如果要用來表示遠近感，則會設定為距離的倒數（1/距離），例如表示一個無限遠的距離時，我們會將w 設定為0
        //
        //  平移：假設 x、y、z 平移量分別為 Tx、 Ty、 Tz
        //  https://openhome.cc/Gossip/ComputerGraphics/images/homogeneousCoordinate-1.jpg
        //
        //  縮放：假設 x、y、z 的縮放比例分別為a、b、c
        //  https://openhome.cc/Gossip/ComputerGraphics/images/homogeneousCoordinate-2.jpg
        //
        //  旋轉：
        //  https://openhome.cc/Gossip/ComputerGraphics/images/homogeneousCoordinate-3.jpg
        //
        
        let dataSize = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        // 創建一個函數組成的 Library庫
        guard let library = device.makeDefaultLibrary() else { return }
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        // 可編程函數 處理渲染過程中的各個頂點
        rpld.vertexFunction = vertex_func
        // 可編程函數 處理渲染過程中的各個片段 ~~ 顏色
        rpld.fragmentFunction = frag_func
        // bgra8Unorm 具有BGRA順序
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            // 同步建立並返回渲染物件狀態
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
        // 設定渲染物件的狀態
        commandEncoder?.setRenderPipelineState(rps)
        // 根據齊次座標設定的緩衝器
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        commandEncoder?.endEncoding()
        // 實際繪圖的 function
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
        // 實際繪圖的 function
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
