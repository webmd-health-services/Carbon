using System;

namespace Carbon.Security
{
    [Flags]
    public enum ContainerInheritanceFlags
    {
        /// <summary>
        /// Apply permission to the container.
        /// </summary>
        Container = 1,
        /// <summary>
        /// Apply permissions to all sub-containers.
        /// </summary>
        SubContainers = 2,
        /// <summary>
        /// Apply permissions to all leaves.
        /// </summary>
        Leaves = 4,
        /// <summary>
        /// Apply permissions to child containers.
        /// </summary>
        ChildContainers = 8,
        /// <summary>
        /// Apply permissions to child leaves.
        /// </summary>
        ChildLeaves = 16,

        /// <summary>
        /// Apply permission to the container and all sub-containers.
        /// </summary>
        ContainerAndSubContainers = Container|SubContainers,
        /// <summary>
        /// Apply permissionto the container and all leaves.
        /// </summary>
        ContainerAndLeaves = Container|Leaves,
        /// <summary>
        /// Apply permission to all sub-containers and all leaves.
        /// </summary>
        SubContainersAndLeaves = SubContainers | Leaves,
        /// <summary>
        /// Apply permission to container and child containers.
        /// </summary>
        ContainerAndChildContainers = Container|ChildContainers,
        /// <summary>
        /// Apply permission to container and child leaves.
        /// </summary>
        ContainerAndChildLeaves = Container|ChildLeaves,
        /// <summary>
        /// Apply permission to container, child containers, and child leaves.  
        /// </summary>
        ContainerAndChildContainersAndChildLeaves = Container|ChildContainers|ChildLeaves,
        /// <summary>
        /// Apply permission to container, all sub-containers, and all leaves.
        /// </summary>
        ContainerAndSubContainersAndLeaves = Container|SubContainers|Leaves,
        /// <summary>
        /// Apply permission to child containers and child leaves.
        /// </summary>
        ChildContainersAndChildLeaves = ChildContainers|ChildLeaves
    }
}
