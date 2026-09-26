# Spree Supplier Price

Spree 6.0.0.beta4 独立插件。下单快照和佣金分支已实现，尚未运行验证或安装到宿主。

## 接入

Engine 注册 carts_complete_workflow、order_complete_workflow 和 commissions_commission_order_service。Carts::Complete 在 PREPARE 创建草稿后、付款之前捕获快照；后台草稿在付款前执行同样检查。供货价佣金在 place_order 后、自动履约前写入，原生 order.placed 订阅者再幂等重放。

CommissionOrder 仅覆盖 commission_seller，普通商品调用 super；供货价商品无需配置 CommissionRate。保留原生事务、唯一索引和汇总，不修改 SellerTransfer / SellerPayout。源码依据为官方 spree/spree 的 v6.0.0.beta4 标签，对应 carts/complete.rb、orders/complete.rb、commissions/commission_order.rb、calculate_line.rb、resolve_tax_rate.rb 和 core/dependencies.rb。私有方法存在版本耦合，升级须复核。

## 快照与金额

LineItem 保存供货单价、币种、报价记录 ID 和结算模式。第一次准备结算时冻结；失败重试不换用新报价，需要改约则新建草稿。旧订单的 NULL 模式仍走普通佣金。模型验证禁止修改快照，直接 SQL/update_columns 不属于支持接口。

当前口径：佣金 = 折后未税商品金额 - 快照供货价 × 数量。原生税解析器计算佣金税；供货价分支不套用普通费率的上下限、显式税率或配送佣金。运费仍由原生账本处理。最终到账因此不保证仅等于供货价乘数量。缺价、币种不匹配和负毛利拒绝结算；零毛利仍记录佣金。beta4 佣金字段仅两位小数，本版拒绝三位小数币种。

SupplierPrice 提交和审核人均使用 Spree.admin_user_class，目前仅控制台管理，无新增 UI 或 API。

## 安装与测试

宿主 server/Gemfile 添加 gem 'spree_supplier_price', path: '../spree_supplier_price'，先在测试环境执行：

    bundle install
    bin/rails spree_supplier_price:install:migrations
    RAILS_ENV=test bin/rails db:prepare
    bundle exec rspec ../spree_supplier_price/spec
    bin/rails zeitwerk:check

Docker 开发环境另需挂载 ./spree_supplier_price:/spree_supplier_price，匹配 /rails 的相对路径。生产构建需在 bundle install 前复制插件；预构建镜像不包含本地插件。未自动修改宿主依赖、Docker 配置或数据库。

已有 9 个服务用例和 19 个 Rails 集成场景，集成测试强制 test 环境并加载宿主 spec/rails_helper，可通过 SPREE_HOST_ROOT 指定宿主位置。尚需真实购物车支付、拆单、并发和 SellerTransfer 端到端验证。

当前无宿主 Ruby，Docker 执行被自动审批服务 HTTP 503 阻断。未执行 Ruby 语法检查、RSpec、迁移或 Rails 启动，不得视为通过测试或可上线。

