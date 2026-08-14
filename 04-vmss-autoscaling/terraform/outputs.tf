output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "load_balancer_public_ip" {
  value = azurerm_public_ip.pip_lb.ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.bepool.id
}
