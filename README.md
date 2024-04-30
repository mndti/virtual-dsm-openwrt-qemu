# Virtual DSM - OpenWrt - qemu-system-x86_64

- This project was created for testing and deciding to share with other users.
- The English language was translated by Google, so if there is any error, I apologize, as I am Brazilian.
- Este projeto foi criado para testes e decidi compartilhar com outros usuários.

## Install / Instalar
<pre><code>sh <(wget -qO- https://raw.githubusercontent.com/mndti/virtual-dsm-openwrt-qemu/main/vdsm_install.sh)</code></pre>

## start / stop / iniciar / parar
[virtual-dsm] is the default name, if changed use the defined name.<br>
[virtual-dsm] é o nome padrão, se alterado, use o nome definido.
<pre>
  <code>/etc/init.d/virtual-dsm start</code>
  <code>/etc/init.d/virtual-dsm stop</code>
</pre>

### Requirements / Requisitos
**hardware**
- CPU: x86_64 with KVM
- FREE DISK SPACE: 18GB (boot[110MB], system[12GB], disk1[6GB])
- RAM: 1GB

**opkg**
- curl unzip
- qemu-img kmod-tun qemu-bridge-helper qemu-x86_64-softmmu
- kmod-kvm-intel intel-microcode iucode-tool (intel)
- kmod-kvm-amd amd64-microcode (amd)

**Testing on / Testado em**
- CPU: Intel N5100
- RAM: 12GB
- NVME: 256GB
- LAN: 4x, Intel i225-V, 2.5G
- Openwrt: 23.05.3 stable

### Limitations / Limitações
- The Virtual Machine Manager package is not available
- Surveillance Station will not include any free licenses
- Virtual Machine Manager não está disponível
- Surveillance Station não incluirá nenhuma licença gratuita

### Virtual DSM - OpenWrt - docker
Link: https://github.com/vdsm/virtual-dsm

#### THANKS
All work was based on the Virtual DSM in a Docker container project by user kroese.<br>
Link: https://github.com/vdsm/virtual-dsm

**Attention**
- This software should be used for testing purposes only!!!
- Commercial use is not permitted and strictly forbidden!!!
- DSM and all Parts are under Copyright / Ownership or Registered Trademark by Synology Inc!!!
- This project is not affiliated, sponsored, or endorsed by Synology, Inc!!!

**Atenção**
- Este software deve ser usado apenas para fins de testes!!!
- O uso comercial não é permitido e estritamente proibido!!!
- A Synology e seus licenciantes são proprietários e retém todos os direitos, títulos e interesses sobre o Software e todos os direitos autorais e de propriedade intelectual nele contidos!!!
- Este projeto não é afiliado, patrocinado ou endossado pela Synology, Inc!!!

**License**<br>
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

**Licença**<br>
O SOFTWARE É FORNECIDO "COMO ESTÁ", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA, INCLUINDO, MAS NÃO SE LIMITANDO ÀS GARANTIAS DE COMERCIALIZAÇÃO, ADEQUAÇÃO A UM DETERMINADO FIM E NÃO VIOLAÇÃO. EM HIPÓTESE ALGUMA OS AUTORES OU DETENTORES DE DIREITOS AUTORAIS SERÃO RESPONSÁVEIS POR QUALQUER RECLAMAÇÃO, DANOS OU OUTRA RESPONSABILIDADE, SEJA EM UMA AÇÃO DE CONTRATO, ATO ILÍCITO OU DE OUTRA FORMA, DECORRENTE DE, OU EM CONEXÃO COM O SOFTWARE OU O USO OU OUTRAS NEGOCIAÇÕES NO PROGRAMAS.
