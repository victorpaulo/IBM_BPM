 #!/bin/bash

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

log_file="/tmp/log.out"
IM_HOME=/opt/IBM/IM
IHS_HOME=/opt/IBM/HTTPServer
PLG_HOME=/opt/IBM/Plugin
WCT_HOME=/opt/IBM/Toolbox

echo "BEGIN..." | tee -a $log_file

ulimit -n 65535

mkdir -p /tmp/http_server /tmp/IM_server

echo "Setting the hosts on file [/etc/hosts] for the topology."

echo "192.168.1.1 db2.bb.com" > /etc/hosts
echo "192.168.1.2 bpm.bb.com" >> /etc/hosts
echo "192.168.1.3 ihs.bb.com" >> /etc/hosts


echo "Unzipping  Installation Manager IM v1.7.3" | tee -a $log_file
echo "CMD> [unzip /vagrant/binary_ihs/agent.installer.linux.gtk.x86_1.7.3000.20140521_1925.zip -d /tmp/IM_server]"
unzip /vagrant/binary_ihs/agent.installer.linux.gtk.x86_1.7.3000.20140521_1925.zip -d /tmp/IM_server

echo "Descompactando o IHS 8.5.5" | tee -a $log_file
for line in /vagrant/binary_ihs/WAS_Liberty_Core_*.zip
do
	echo "CMD> [unzip $line -d /tmp/http_server]"
	unzip $line -d /tmp/http_server > /dev/null
done

REPOSITORY_IM_DIR=/tmp/IM_server

echo "Installing binaries of Installation Manager..." | tee -a $log_file
    $REPOSITORY_IM_DIR/tools/imcl install com.ibm.cic.agent \
        -acceptLicense -installationDirectory $IM_HOME -repositories $REPOSITORY_IM_DIR \
        -showVerboseProgress -log /tmp/silent_im_install.log

echo "Installing the IBM HTTP Server binaries - IHS 8.5.5" | tee -a $log_file 
 $IM_HOME/eclipse/tools/imcl \
        install com.ibm.websphere.IHS.v85,core.feature,arch.64bit \
        -installationDirectory ${IHS_HOME} \
        -properties user.ihs.httpPort=80 \
        -acceptLicense \
        -repositories /tmp/http_server/

echo "Installing the IBM WebSphere Plugin for the IHS v8.5.5" | tee -a $log_file 		
 $IM_HOME/eclipse/tools/imcl \
        install com.ibm.websphere.PLG.v85,core.feature,com.ibm.jre.6_64bit \
        -installationDirectory ${PLG_HOME} \
        -acceptLicense \
        -repositories /tmp/http_server/
		
echo "Installing the IBM WebSphere Customization Toolbox - WCT v8.5.5" | tee -a $log_file 
 $IM_HOME/eclipse/tools/imcl \
		install com.ibm.websphere.WCT.v85 \
		-installationDirectory ${WCT_HOME} \
		-acceptLicense \
		-repositories /tmp/http_server/

echo "Creating definition of IHS by WCT tool..." | tee -a $log_file 		
${WCT_HOME}/WCT/wctcmd.sh -tool pct -createDefinition \
	-defLocName ${PLG_HOME} -defLocPathname ${PLG_HOME} \
	-response /vagrant/pct_responsefile.txt
