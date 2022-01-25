#include <linux/build-salt.h>
#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(.gnu.linkonce.this_module) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used __section(__versions) = {
	{ 0xb3753869, "module_layout" },
	{ 0xde4c1a24, "param_ops_charp" },
	{ 0x478f00e1, "pci_unregister_driver" },
	{ 0x24694125, "__pci_register_driver" },
	{ 0xe2d5255a, "strcmp" },
	{ 0xc5850110, "printk" },
	{ 0x30d95535, "_dev_notice" },
	{ 0x18616700, "_dev_err" },
	{ 0x2b54d1d5, "dma_free_attrs" },
	{ 0xfda0bdf3, "dma_alloc_attrs" },
	{ 0x3b823a96, "_dev_info" },
	{ 0xc87520bc, "__uio_register_device" },
	{ 0x2fa8953f, "pci_irq_vector" },
	{ 0xc317f50a, "__dynamic_dev_dbg" },
	{ 0x93a219c, "ioremap_nocache" },
	{ 0x19f142b0, "sysfs_create_group" },
	{ 0x48e065be, "pci_alloc_irq_vectors_affinity" },
	{ 0x54ea6dfe, "xen_start_flags" },
	{ 0x731dba7a, "xen_domain_type" },
	{ 0x32ffdcca, "dma_set_coherent_mask" },
	{ 0xd8fd6a9a, "dma_set_mask" },
	{ 0x42980214, "pci_enable_device" },
	{ 0xf5cb25c8, "kmem_cache_alloc_trace" },
	{ 0x35216b26, "kmalloc_caches" },
	{ 0x52f9b7d1, "pci_check_and_mask_intx" },
	{ 0x606f94b1, "pci_intx" },
	{ 0x76f8e404, "pci_cfg_access_unlock" },
	{ 0x66668a03, "pci_cfg_access_lock" },
	{ 0xfee56dca, "pci_set_master" },
	{ 0x3fedf984, "pci_reset_function" },
	{ 0x276940fc, "pci_clear_master" },
	{ 0x3673a548, "remap_pfn_range" },
	{ 0xb665f56d, "__cachemode2pte_tbl" },
	{ 0x445a81ce, "boot_cpu_data" },
	{ 0x478cc26a, "pci_disable_msix" },
	{ 0x37a0cba, "kfree" },
	{ 0xae630ce8, "pci_disable_device" },
	{ 0xedc03953, "iounmap" },
	{ 0xb249b3bc, "uio_unregister_device" },
	{ 0x461f3e7c, "sysfs_remove_group" },
	{ 0x656e4a6e, "snprintf" },
	{ 0x2ea2c95c, "__x86_indirect_thunk_rax" },
	{ 0xdecd0b29, "__stack_chk_fail" },
	{ 0x23d105c9, "pci_enable_sriov" },
	{ 0x323d4ee3, "pci_disable_sriov" },
	{ 0xbff1f8ce, "pci_num_vf" },
	{ 0x3c80c06c, "kstrtoull" },
	{ 0xbdfb6dbb, "__fentry__" },
};

MODULE_INFO(depends, "uio");


MODULE_INFO(srcversion, "964321D18A4C7273AE8B3D5");
