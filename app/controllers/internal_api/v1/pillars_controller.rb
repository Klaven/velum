# Serve the pillar information
class InternalApi::V1::PillarsController < InternalApiController
  def show
    ok content: pillar_contents.merge(
      registry_contents
    ).merge(
      cloud_framework_contents
    )
  end

  private

  def pillar_contents
    pillar_struct = {}.tap do |h|
      Pillar.simple_pillars.each do |k, v|
        h[v] = Pillar.value(pillar: k.to_sym) unless Pillar.value(pillar: k.to_sym).nil?
      end
    end
    {}.tap do |json_response|
      pillar_struct.each do |key, value|
        json_response.deep_merge! key.split(":").reverse.inject(value) { |a, n| { n => a } }
      end
    end.deep_symbolize_keys
  end

  def registry_contents
    registries = Registry.all.map do |reg|
      registry = {}
      registry[:url]  = reg.url
      registry[:cert] = reg.certificate.try(:certificate)
      reg.registry_mirrors.each do |mirror|
        registry[:mirrors] ||= []
        registry[:mirrors].push(
          url:  mirror.url,
          cert: mirror.certificate.try(:certificate)
        )
      end
      registry
    end
    { registries: registries }
  end

  def cloud_framework_contents
    case Pillar.value(pillar: :cloud_framework)
    when "ec2"
      ec2_cloud_contents
    when "azure"
      azure_cloud_contents
    else
      {}
    end
  end

  def ec2_cloud_contents
    {
      cloud: {
        framework: "ec2",
        profiles:  {
          cluster_node: {
            size:               Pillar.value(pillar: :cloud_worker_type),
            network_interfaces: [
              {
                DeviceIndex:              0,
                AssociatePublicIpAddress: false,
                SubnetId:                 Pillar.value(pillar: :cloud_worker_subnet),
                SecurityGroupId:          Pillar.value(pillar: :cloud_worker_security_group)
              }
            ]
          }
        }
      }
    }
  end

  def azure_cloud_contents
    {
      cloud: {
        framework: "azure",
        providers: {
          azure: {
            subscription_id: Pillar.value(pillar: :azure_subscription_id),
            tenant:          Pillar.value(pillar: :azure_tenant_id),
            client_id:       Pillar.value(pillar: :azure_client_id),
            secret:          Pillar.value(pillar: :azure_secret)
          }
        },
        profiles:  {
          cluster_node: {
            size:                   Pillar.value(pillar: :cloud_worker_type),
            resource_group:         Pillar.value(pillar: :cloud_worker_resourcegroup),
            network_resource_group: Pillar.value(pillar: :cloud_worker_resourcegroup),
            network:                Pillar.value(pillar: :cloud_worker_net),
            subnet:                 Pillar.value(pillar: :cloud_worker_subnet)
          }
        }
      }
    }
  end
end
