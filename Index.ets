/**
 * 入口页面
 * 鸿蒙6.0版本
 */
import { TDXWenDaPage } from './TDXWenDa';

@Entry
@Component
struct Index {
  build() {
    Column() {
      // 直接使用通达信问答页面
      TDXWenDaPage()
    }
    .width('100%')
    .height('100%')
  }
}
